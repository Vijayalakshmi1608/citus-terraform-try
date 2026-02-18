resource "aws_route53_zone" "private" {
  name = "testinternal.citus"
  vpc {
    vpc_id = var.vpc_id
  }
  tags = {
    Name = "test-internal-citus-zone"
  }
}

resource "aws_route53_record" "coordinator" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "coordinator.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.10"]
}

resource "aws_route53_record" "worker1" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "worker1.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.11"]
}

resource "aws_route53_record" "worker2" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "worker2.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.12"]
}

resource "aws_route53_record" "coordinator-replica" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "coordinator-replica.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.13"]
}

resource "aws_route53_record" "worker1-replica" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "worker1-replica.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.14"]
}

resource "aws_route53_record" "worker2-replica" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "worker2-replica.testinternal.citus"
  type    = "A"
  ttl     = "300"
  records = ["10.50.1.15"]
} 


