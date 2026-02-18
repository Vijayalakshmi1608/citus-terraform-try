variable "environment" {
  description = "Environment name"
  type        = string
  default     = "trail"
}

variable "aws_access_key_id" {
  description = "AWS access key for CLI configuration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret key for CLI configuration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgresql_password" {
  description = "PostgreSQL password for Citus master instance"
  type        = string
  sensitive   = true
}

variable "mq_password" {
  description = "Password for the Amazon MQ broker user"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "Region"
  type        = string
  default     = ""
}
