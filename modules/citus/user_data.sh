#!/bin/bash
set -e

VOLUME_ID=${volume_id}
DEVICE_NAME="/dev/xvdf"
REGION=${aws_region}
COORDINATOR_DNS=${coordinator_dns}
MOUNT_PATH="/var/lib/postgresql/17/main"
POSTGRES_PASS=${POSTGRES_PASS}
HOSTED_ZONE_ID=${hosted_zone_id}

PGVER=17
PGDATA="/var/lib/postgresql/$PGVER/main"
BACKUP_DIR="${PGDATA}_old"
MNT="/mnt/newvolume"
DEVICE_PATH=""
VOLUME_ID_NO_DASH="${VOLUME_ID#vol-}"

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

  echo "⏳ Waiting for volume to become available after detach..."
  for i in {1..40}; do
    STATE=$(aws ec2 describe-volumes       --volume-ids "$VOLUME_ID" --region "$REGION"       --query "Volumes[0].State" --output text)
    if [ "$STATE" = "available" ]; then
      break
    fi
    sleep 3
  done

  if [ "$STATE" != "available" ]; then
    echo "❌ Volume $VOLUME_ID did not become available after detach"
    exit 1
  fi
fi

#######################################
### ATTACH VOLUME
#######################################
CURRENT_ATTACHMENT=$(aws ec2 describe-volumes   --volume-ids "$VOLUME_ID" --region "$REGION"   --query "Volumes[0].Attachments[0].InstanceId" --output text)

if [ "$CURRENT_ATTACHMENT" = "$INSTANCE_ID" ]; then
  echo "✅ Volume $VOLUME_ID is already attached to this instance"
else
  echo "📎 Attaching $VOLUME_ID as $DEVICE_NAME..."
  aws ec2 attach-volume     --volume-id "$VOLUME_ID"     --instance-id "$INSTANCE_ID"     --device "$DEVICE_NAME"     --region "$REGION"
fi

echo "⏳ Waiting for volume attachment state..."
for i in {1..40}; do
  ATTACH_STATE=$(aws ec2 describe-volumes     --volume-ids "$VOLUME_ID" --region "$REGION"     --query "Volumes[0].Attachments[0].State" --output text)
  ATTACH_INSTANCE=$(aws ec2 describe-volumes     --volume-ids "$VOLUME_ID" --region "$REGION"     --query "Volumes[0].Attachments[0].InstanceId" --output text)

  if [ "$ATTACH_INSTANCE" = "$INSTANCE_ID" ] && [ "$ATTACH_STATE" = "attached" ]; then
    break
  fi
  sleep 3
done

if [ "$ATTACH_INSTANCE" != "$INSTANCE_ID" ] || [ "$ATTACH_STATE" != "attached" ]; then
  echo "❌ Volume did not reach attached state on this instance"
  exit 1
fi

#######################################
### RESOLVE NVMe DEVICE FOR THIS VOLUME
#######################################
echo "⏳ Resolving NVMe device for $VOLUME_ID..."
for i in {1..40}; do
  for candidate in /dev/nvme*n1; do
    [ -e "$candidate" ] || continue
    if command -v nvme >/dev/null 2>&1; then
      serial=$(sudo nvme id-ctrl -v "$candidate" 2>/dev/null | awk -F: '/^sn[[:space:]]*:/ {gsub(/[[:space:]]/, "", $2); print $2; exit}')
      if [ "$serial" = "$VOLUME_ID" ] || [ "$serial" = "$VOLUME_ID_NO_DASH" ]; then
        DEVICE_PATH="$candidate"
        break 2
      fi
    fi
  done
  sleep 3
done

if [ -z "$DEVICE_PATH" ]; then
  DEVICE_PATH="$(readlink -f "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${VOLUME_ID}" 2>/dev/null || true)"
fi

if [ -z "$DEVICE_PATH" ]; then
  echo "❌ Could not map volume $VOLUME_ID to an NVMe block device"
  exit 1
fi

echo "✅ EBS device for $VOLUME_ID: $DEVICE_PATH"


# ====== POSTGRES CONFIG ======
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
sudo tee "$PG_HBA_FILE" >/dev/null <<'EOF'
host    replication     all             ::1/128                 scram-sha-256
host    all             all             172.0.0.0/8             trust
local   all             postgres                                peer
host    all             all             127.0.0.1/32            trust
host    all             all             10.0.0.0/8              trust
hostssl all             all             10.0.0.0/8              trust
host    replication     all             10.0.0.0/8              trust
hostssl all             all             172.0.0.0/8             trust
host    replication     all             172.0.0.0/8             trust
EOF


# Optional: set postgres password (will fail if PG not up yet; ignore errors)
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';" || true



echo "Stopping PostgreSQL..."
sudo systemctl stop postgresql

echo "Creating mount directory..."
sudo mkdir -p $MNT

echo "Checking if EBS volume has a filesystem..."
FS_CHECK=$(sudo file -s "$DEVICE_PATH")

if echo "$FS_CHECK" | grep -q "filesystem"; then
    echo "✅ Volume already has a filesystem — skipping formatting."
else
    echo "🆕 Volume is empty — formatting as ext4."
    sudo mkfs.ext4 "$DEVICE_PATH"
    echo "✅ Formatting completed."
fi

echo "Mounting temporarily..."
sudo mount "$DEVICE_PATH" "$MNT"


echo "Checking if new EBS volume is empty..."
# Fresh ext4 filesystems include a default `lost+found` directory. Treat that
# case as empty so initial PostgreSQL data migration still runs.
if [ -z "$(ls -A "$MNT" | grep -v '^lost+found$')" ]; then
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
sudo mount "$DEVICE_PATH" "$PGDATA"

echo "Setting correct permissions..."
sudo chown -R postgres:postgres $PGDATA
sudo chmod 700 $PGDATA

echo "Updating /etc/fstab..."
DEVICE_UUID=$(sudo blkid -s UUID -o value "$DEVICE_PATH")
FSTAB_ENTRY="UUID=$DEVICE_UUID $PGDATA ext4 defaults,nofail 0 2"
if ! grep -q "UUID=$DEVICE_UUID" /etc/fstab; then
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


# ====== DNS UPDATE (NOTE: this points $COORDINATOR_DNS to THIS instance IP) ======
echo "Updating Route53: $COORDINATOR_DNS -> $INSTANCE_IP"
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" --region "$REGION" --change-batch "{
  \"Comment\": \"Register PG node\",
  \"Changes\": [{
    \"Action\": \"UPSERT\",
    \"ResourceRecordSet\": {
      \"Name\": \"$COORDINATOR_DNS\",
      \"Type\": \"A\",
      \"TTL\": 60,
      \"ResourceRecords\": [{\"Value\": \"$INSTANCE_IP\"}]
    }
  }]
}"

echo "Waiting 60 seconds for DNS propagation..."
sleep 60
sudo -i -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS citus;" || true
sudo -i -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS citus;" || true
sudo -i -u postgres psql -c "SELECT citus_set_coordinator_host('$COORDINATOR_DNS', 5432);" || true
sudo -i -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASS';" || true
