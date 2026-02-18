output "vpc_id" {
  description = "Existing VPC used for deployment"
  value       = var.existing_vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets used for deployment"
  value       = var.existing_private_subnet_ids
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
