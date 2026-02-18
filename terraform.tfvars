# Update these values for your existing AWS network before running `terraform apply`.

# Existing network inputs
existing_vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
existing_private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy"
]
key_name = "your-existing-keypair-name"

# Required credentials / runtime settings
postgresql_password   = "change-me"
aws_region            = "ap-south-1"
volume_availability_zone = "ap-south-1a"

# Optional overrides
cluster_name        = "smac-test"
citus_ami_id        = "ami-0ee5c99d5dc17c9c6"
citus_instance_type = "t3.medium"
