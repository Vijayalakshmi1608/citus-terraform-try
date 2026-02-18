variable "vpc_id" {
  description = "The VPC ID where the private hosted zone will be created."
  type        = string
}

variable "create_coordinator_record" {
  description = "Whether to create the coordinator A record"
  type        = bool
  default     = true
}

variable "create_worker1_record" {
  description = "Whether to create the worker1 A record"
  type        = bool
  default     = true
}

variable "create_worker2_record" {
  description = "Whether to create the worker2 A record"
  type        = bool
  default     = true
}

variable "create_coordinator_replica_record" {
  description = "Whether to create the coordinator-replica A record"
  type        = bool
  default     = true
}

variable "create_worker1_replica_record" {
  description = "Whether to create the worker1-replica A record"
  type        = bool
  default     = true
}

variable "create_worker2_replica_record" {
  description = "Whether to create the worker2-replica A record"
  type        = bool
  default     = true
} 