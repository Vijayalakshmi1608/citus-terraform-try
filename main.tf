module "ebs_volume" {
  source            = "./modules/ebs_volume"
  availability_zone = var.volume_availability_zone
}

module "private_hosted_zone" {
  source = "./modules/private_hosted_zone"
  vpc_id = var.existing_vpc_id
}

module "citus" {
  source                = "./modules/citus"
  vpc_id                = var.existing_vpc_id
  cluster_name          = var.cluster_name
  ami_id                = var.citus_ami_id
  private_subnet_ids    = var.existing_private_subnet_ids
  instance_type         = var.citus_instance_type
  postgresql_password   = var.postgresql_password
  hosted_zone_id        = module.private_hosted_zone.zone_id
  master_test_volume_id = module.ebs_volume.master_citus_volume_id
  coordinator_dns       = module.private_hosted_zone.coordinator_record
  worker1_test_volume_id = module.ebs_volume.worker_citus_1_volume_id
  worker1_dns           = module.private_hosted_zone.worker1_record
  worker2_test_volume_id = module.ebs_volume.worker_citus_2_volume_id
  worker2_dns           = module.private_hosted_zone.worker2_record
  aws_region            = var.aws_region
  key_name              = var.key_name
  PGDATA                = "/var/lib/postgresql/17/main"
}
