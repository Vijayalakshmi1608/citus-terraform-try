output "master_citus_volume_id" {
  value = aws_ebs_volume.master_citus_test.id
}

output "worker_citus_1_volume_id" {
  value = aws_ebs_volume.worker_citus_1_test.id
}

output "worker_citus_2_volume_id" {
  value = aws_ebs_volume.worker_citus_2_test.id
} 

output "master_citus_replica_volume_id" {
  value = aws_ebs_volume.master_citus_replica_test.id
}

output "worker_citus_1_replica_volume_id" {
  value = aws_ebs_volume.worker_citus_1_replica_test.id
}

output "worker_citus_2_replica_volume_id" {
  value = aws_ebs_volume.worker_citus_2_replica_test.id
} 