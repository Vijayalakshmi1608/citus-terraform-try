output "zone_id" {
  value = aws_route53_zone.private.zone_id
}

output "zone_name" {
  value = aws_route53_zone.private.name
}

output "coordinator_record" {
  value = aws_route53_record.coordinator.name
}

output "worker1_record" {
  value = aws_route53_record.worker1.name
}

output "worker2_record" {
  value = aws_route53_record.worker2.name
}

output "coordinator_record_replica" {
  value = aws_route53_record.coordinator-replica.name
}

output "worker1_record_replica" {
  value = aws_route53_record.worker1-replica.name
}

output "worker2_record_replica" {
  value = aws_route53_record.worker2-replica.name
} 