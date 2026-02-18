variable "environment" {
  description = "Environment name"
  type        = string
  default     = "trail"
}

variable "postgresql_password" {
  description = "PostgreSQL password for Citus master instance"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region where resources are created"
  type        = string
  default     = "ap-south-1"
}

variable "existing_vpc_id" {
  description = "Existing VPC ID where Citus will be deployed"
  type        = string
}

variable "existing_private_subnet_ids" {
  description = "Private subnet IDs in the existing VPC"
  type        = list(string)
}

variable "cluster_name" {
  description = "Cluster name used for tagging"
  type        = string
  default     = "smac-test"
}

variable "citus_ami_id" {
  description = "AMI ID for Citus instances"
  type        = string
  default     = "ami-0ee5c99d5dc17c9c6"
}

variable "citus_instance_type" {
  description = "Instance type for Citus nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "volume_availability_zone" {
  description = "Availability zone for Citus EBS volumes"
  type        = string
  default     = "ap-south-1a"
}
