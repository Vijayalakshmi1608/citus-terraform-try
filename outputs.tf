output "vpc_id" {
  value = module.vpc.vpc_id
}
output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

# Citus Module Outputs
output "citus_security_group_id" {
  description = "ID of the Citus security group"
  value       = module.citus.citus_security_group_id
}

output "citus_master_launch_template_id" {
  description = "ID of the Citus master launch template"
  value       = module.citus.citus_master_launch_template_id
}

output "citus_worker1_launch_template_id" {
  description = "ID of the Citus worker1 launch template"
  value       = module.citus.citus_worker1_launch_template_id
}

output "citus_worker2_launch_template_id" {
  description = "ID of the Citus worker2 launch template"
  value       = module.citus.citus_worker2_launch_template_id
}

output "ec2_volume_attach_role_arn" {
  description = "ARN of the EC2 Volume Attach IAM role"
  value       = module.citus.ec2_volume_attach_role_arn
}

