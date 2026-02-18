variable "vpc_id" {
  description = "VPC ID where the Citus instances will be launched"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster for tagging purposes"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Citus instances"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where Citus instances will be launched"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for Citus instances"
  type        = string
}

variable "postgresql_password" {
  description = "PostgreSQL password for Citus master instance"
  type        = string
  sensitive   = true
}

variable "master_test_volume_id" {
  description = "EBS volume ID for Citus master instance"
  type        = string
}

variable "worker1_test_volume_id" {
  description = "EBS volume ID for Citus worker1 instance"
  type        = string
}

variable "worker2_test_volume_id" {
  description = "EBS volume ID for Citus worker2 instance"
  type        = string
}

variable "worker2_dns" {
  description = "DNS name for Citus worker2"
  type        = string
}

variable "coordinator_dns" {
  description = "DNS name for Citus coordinator"
  type        = string
}

variable "worker1_dns" {
  description = "DNS name for Citus worker1"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "hosted_zone_id" {
  description = "hosted_zone_id"
  type        = string
} 

variable "PGDATA" {
  description = "PGDATA"
  type        = string
} 




