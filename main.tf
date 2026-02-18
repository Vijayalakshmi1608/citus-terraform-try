module "vpc" {
  source           = "./modules/vpc"
  vpc_cidr         = "10.50.0.0/16"
  azs              = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets  = ["10.50.1.0/24", "10.50.2.0/24"]
  public_subnets   = ["10.50.101.0/24", "10.50.102.0/24"]
  environment      = "test"
  region           = "ap-south-1"
  private_route_table_ids = module.nat_gateway.private_route_table_ids
}

module "nat_gateway" {
  source             = "./modules/nat_gateway"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  environment      = "test"
}

module "security_group" {
  source       = "./modules/security_group"
  vpc_id       = module.vpc.vpc_id
  cluster_name = "test-eks-cluster"
}

module "bastion" {
  source            = "./modules/bastion"
  ami_id            = "ami-02521d90e7410d9f0"  # Amazon Linux 2 AMI in ap-south-1
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  key_name          = "test-key-new-acc"  # Make sure to create this key pair in AWS
  security_group_id = module.security_group.bastion_sg_id
  name              = "smac-test"
  #cluster_name      = module.eks.cluster_name
  aws_region        = "ap-south-1"
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

module "ebs_volume" {
  source            = "./modules/ebs_volume"
  availability_zone = "ap-south-1a"
}

module "private_hosted_zone" {
  source = "./modules/private_hosted_zone"
  vpc_id = module.vpc.vpc_id
}

module "citus" {
  source              = "./modules/citus"
  vpc_id              = module.vpc.vpc_id
  cluster_name        = "smac-test"
  ami_id              = "ami-0ee5c99d5dc17c9c6"  # Amazon Linux 2 AMI in ap-south-1
  private_subnet_ids  = module.vpc.private_subnet_ids
  #instance_type_master = "t3.medium"
  instance_type        = "t3.medium"
  postgresql_password = var.postgresql_password
  hosted_zone_id      = module.private_hosted_zone.zone_id
  master_test_volume_id    = module.ebs_volume.master_citus_volume_id
  coordinator_dns     = module.private_hosted_zone.coordinator_record
  worker1_test_volume_id   = module.ebs_volume.worker_citus_1_volume_id
  worker1_dns         = module.private_hosted_zone.worker1_record
  worker2_test_volume_id   = module.ebs_volume.worker_citus_2_volume_id 
  worker2_dns         = module.private_hosted_zone.worker2_record
  aws_region          = "ap-south-1"
  key_name            = "test-key-new-acc" 
  PGDATA="/var/lib/postgresql/17/main"
  #eks_nodes_sg_id     = module.security_group.eks_nodes_sg
  #bastion_sg_id       = module.security_group.bastion_sg_id
}

module "citus_replica" {
  source             = "./modules/citus_replica"
  vpc_id              = module.vpc.vpc_id
  cluster_name        = "smac-test"
  ami_id              = "ami-0ee5c99d5dc17c9c6"
  private_subnet_ids  = module.vpc.private_subnet_ids
  #instance_type_master = "m6i.large"
  instance_type        = "t3.medium"
  postgresql_password = var.postgresql_password
  hosted_zone_id      = module.private_hosted_zone.zone_id
  master_test_volume_id    = module.ebs_volume.master_citus_replica_volume_id
  coordinator_dns     = module.private_hosted_zone.coordinator_record 
  replica_coordinator_dns = module.private_hosted_zone.coordinator_record_replica 
  worker1_test_volume_id   = module.ebs_volume.worker_citus_1_replica_volume_id 
  worker1_dns         = module.private_hosted_zone.worker1_record_replica 
  worker1_primary_dns = module.private_hosted_zone.worker1_record
  worker2_test_volume_id    = module.ebs_volume.worker_citus_2_replica_volume_id 
  worker2_dns         = module.private_hosted_zone.worker2_record_replica 
  worker2_primary_dns = module.private_hosted_zone.worker2_record
  aws_region          = "ap-south-1" 
  key_name            = "test-key-new-acc"
  PGDATA="/var/lib/postgresql/17/main"   
  #depends_on = [module.citus]
}

module "ssm_parameter_1" {
  source      = "./modules/parameter_store"
  name        = "/myapp/db_password"
  type        = "SecureString"
  value       = "supersecretpassword"
  description = "Database password for myapp"
  overwrite   = true
}

module "ssm_parameter_2" {
  source      = "./modules/parameter_store"
  name        = "/myapp/api_key"
  type        = "String"
  value       = "my-api-key-123"
  description = "API key for myapp"
  overwrite   = true
}






