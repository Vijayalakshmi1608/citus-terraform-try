output "citus_security_group_id" {
  description = "ID of the Citus security group"
  value       = aws_security_group.citus_sg.id
}

output "citus_master_launch_template_id" {
  description = "ID of the Citus master launch template"
  value       = aws_launch_template.citus_master_test.id
}

output "citus_worker1_launch_template_id" {
  description = "ID of the Citus worker1 launch template"
  value       = aws_launch_template.citus_worker1_test.id
}

output "citus_worker2_launch_template_id" {
  description = "ID of the Citus worker2 launch template"
  value       = aws_launch_template.citus_worker2_test.id
}

output "ec2_volume_attach_role_arn" {
  description = "ARN of the EC2 Volume Attach IAM role"
  value       = aws_iam_role.ec2_volume_attach_role.arn
}

output "citus_instance_profile_name" {
  description = "Name of the Citus instance profile"
  value       = aws_iam_instance_profile.citus_instance_profile.name
}

output "citus_sg_id" {
  value = aws_security_group.citus_sg.id
} 
