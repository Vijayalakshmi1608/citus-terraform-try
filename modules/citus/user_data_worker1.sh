#!/bin/bash
set -e

REGION=${aws_region}
DEVICE_NAME="/dev/xvdf"
PORT="5432"
COORDINATOR_DNS=${coordinator_dns}
WORKER1_DNS=${worker1_dns}
MOUNT_PATH="/var/lib/postgresql/17/main"
PG_VERSION_FILE="$MOUNT_PATH/PG_VERSION"
VOLUME_ID=${worker1_volume_id}
POSTGRES_PASS=${POSTGRES_PASS}
DB_USER="postgres"
DB_NAME="postgres"
HOSTED_ZONE_ID=${hosted_zone_id}

PGVER=17
DEVICE="/dev/nvme1n1"   # New EBS disk
PGDATA="/var/lib/postgresql/$PGVER/main"
BACKUP_DIR="${PGDATA}_old"
MNT="/mnt/newvolume"
FSTAB_ENTRY="$DEVICE $PGDATA ext4 defaults,nofail 0 2"

#######################################
### GET INSTANCE METADATA
#######################################
get_token() {
  curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

TOKEN=$(get_token)

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

echo "📌 Instance: $INSTANCE_ID | AZ: $AZ | IP: $INSTANCE_IP"

#######################################
### CHECK EBS VOLUME AZ
#######################################
VOL_AZ=$(aws ec2 describe-volumes \
  --volume-ids "$VOLUME_ID" --region "$REGION" \
  --query "Volumes[0].AvailabilityZone" --output text)

if [ "$VOL_AZ" != "$AZ" ]; then
  echo "❌ Volume AZ $VOL_AZ != Instance AZ $AZ"
  exit 1
fi

#######################################
### DETACH IF ATTACHED ELSEWHERE
#######################################
ATTACHED_INSTANCE=$(aws ec2 describe-volumes \
  --volume-ids "$VOLUME_ID" --region "$REGION" \
  --query "Volumes[0].Attachments[0].InstanceId" --output text)

if [[ "$ATTACHED_INSTANCE" != "None" && "$ATTACHED_INSTANCE" != "$INSTANCE_ID" ]]; then
  echo "⚠️ Detaching from $ATTACHED_INSTANCE"
  aws ec2 detach-volume --volume-id "$VOLUME_ID" --region "$REGION"
  sleep 10
fi

#######################################
### ATTACH VOLUME
#######################################
echo "📎 Attaching $VOLUME_ID as $DEVICE_NAME..."
aws ec2 attach-volume \
  --volume-id "$VOLUME_ID" \
  --instance-id "$INSTANCE_ID" \
  --device "$DEVICE_NAME" \
  --region "$REGION"

#######################################
### WAIT FOR NVMe DEVICE
#######################################
echo "⏳ Waiting for NVMe device..."
for i in {1..30}; do
  DEVICE_PATH=$(lsblk -o NAME,TYPE | awk '/disk/ && /nvme/ {print "/dev/"$1; exit}')
  if [ -n "$DEVICE_PATH" ]; then
    break
  fi
  sleep 3
done

if [ -z "$DEVICE_PATH" ]; then
  echo "❌ NVMe device not found"
  exit 1
fi

echo "✅ EBS device: $DEVICE_PATH"

sudo pg_conftool 17 main set shared_preload_libraries citus
sudo pg_conftool 17 main set listen_addresses '*'
sudo pg_conftool 17 main set max_connections 5000
sudo pg_conftool 17 main set max_logical_replication_workers 500
sudo pg_conftool 17 main set max_replication_slots 500

sudo pg_conftool 17 main set wal_level replica
sudo pg_conftool 17 main set max_wal_senders 10
sudo pg_conftool 17 main set wal_keep_size 512MB
sudo pg_conftool 17 main set hot_standby on


PG_HBA_FILE="/etc/postgresql/17/main/pg_hba.conf"

cat <<EOF | sudo tee "$PG_HBA_FILE" > /dev/null
host    replication     all             ::1/128                 scram-sha-256
host    all             all             172.0.0.0/8             trust
local   all             postgres                                 peer
host    all             all             127.0.0.1/32            trust
host    all             all             10.0.0.0/8             trust
hostssl all             all             10.0.0.0/8              trust
host    replication     all             10.0.0.0/8              trust
hostssl all             all             172.0.0.0/8              trust
host    replication     all             172.0.0.0/8              trust
EOF

echo "✅ pg_hba.conf overwritten with custom rules."

# Optional: set postgres password (will fail if PG not up yet; ignore errors)
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';" || true



echo "Stopping PostgreSQL..."
sudo systemctl stop postgresql

echo "Creating mount directory..."
sudo mkdir -p $MNT

echo "Checking if EBS volume has a filesystem..."
FS_CHECK=$(sudo file -s $DEVICE)

if echo "$FS_CHECK" | grep -q "filesystem"; then
    echo "✅ Volume already has a filesystem — skipping formatting."
else
    echo "🆕 Volume is empty — formatting as ext4."
    sudo mkfs.ext4 $DEVICE
    echo "✅ Formatting completed."
fi

echo "Mounting temporarily..."
sudo mount $DEVICE $MNT

echo "Checking if new EBS volume is empty..."
if [ -z "$(ls -A $MNT | grep -v 'lost+found')" ]; then
    echo "✅ New volume is EMPTY — proceeding with PostgreSQL data migration."

    echo "Backing up existing PostgreSQL data..."
    sudo mv $PGDATA $BACKUP_DIR

    echo "Re-create Postgres data directory..."
    sudo mkdir -p $PGDATA

    echo "Copying Postgres data to new volume..."
    sudo rsync -av $BACKUP_DIR/ $MNT/
else
    echo "⚠️ New volume is NOT empty — skipping backup & restore."
fi

echo "Unmounting temp mount..."
sudo umount $MNT

echo "Mounting volume to Postgres data path..."
sudo mount $DEVICE $PGDATA

echo "Setting correct permissions..."
sudo chown -R postgres:postgres $PGDATA
sudo chmod 700 $PGDATA

echo "Updating /etc/fstab..."
if ! grep -q "$DEVICE" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
fi

echo "Reloading fstab..."
sudo mount -a

echo "Starting PostgreSQL..."
sudo systemctl start postgresql

echo "Checking PostgreSQL status..."
sudo systemctl status postgresql --no-pager

echo "Disk mapping verification:"
df -h | grep post

echo "✅ Migration completed successfully!"
echo "Old Postgres data is stored here: $BACKUP_DIR"



echo "🛠️  Adding DNS record for $WORKER1_DNS -> $INSTANCE_IP"

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --region $REGION --change-batch '{
  "Comment": "Register worker node in Route 53",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "'"$WORKER1_DNS"'",
      "Type": "A",
      "TTL": 60,
      "ResourceRecords": [{"Value": "'"$INSTANCE_IP"'"}]
    }
  }]
}'

echo "⏳ Waiting 60 seconds for DNS propagation..."
sleep 60


sudo -i -u postgres psql -c "CREATE EXTENSION citus;" || true

echo "🔍 Checking if $COORDINATOR_DNS:$PORT is reachable..."
if pg_isready -h "$COORDINATOR_DNS" -p "$PORT" > /dev/null 2>&1; then
    echo "✅ Coordinator is reachable. Proceeding with registration."
    sudo PGPASSWORD="$POSTGRES_PASS" psql -h "$COORDINATOR_DNS" -U postgres  -c "SELECT master_add_node('$WORKER1_DNS', 5432);" || true
else
    echo "❌ Coordinator is not reachable. Terminating this EC2 to save costs."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    exit 0
fi

# # echo "🔍 Fetching registered Citus worker nodes..."
# NODES=$(psql -h "$COORDINATOR" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT nodename, nodeport FROM pg_dist_node;")
# PGPASSWORD="$POSTGRES_PASS" psql -h "$COORDINATOR_DNS" -U postgres  -c "SELECT master_add_node('$WORKER2_DNS', 5432);" || true



# Install AWS SSM Agent
cd /tmp
wget https://s3.ap-south-1.amazonaws.com/amazon-ssm-ap-south-1/latest/debian_amd64/amazon-ssm-agent.deb -O amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sudo systemctl status amazon-ssm-agent
amazon-ssm-agent --version

 sudo PGPASSWORD="Admin@123" psql -h "coordinator.internal.citus" -U postgres  -c "SELECT master_add_node('worker1.internal.citus', 5432);"