# Create Security Group for Citus instances
resource "aws_security_group" "citus_sg" {
  name_prefix = "citus-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL/Citus port"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-citus-sg"
  }
}

# Create IAM Role for EC2 Volume Attachment
resource "aws_iam_role" "ec2_volume_attach_role" {
  name = "EC2VolumeAttachRoleTest"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM Policy for Route53 DNS Update
resource "aws_iam_policy" "allow_route53_dns_update" {
  name = "AllowRoute53DNSUpdateTest"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      }
    ]
  })
}

# Create IAM Policy for EC2 Volume Attachment
resource "aws_iam_policy" "ec2_volume_attach_policy" {
  name = "EC2VolumeAttachPolicyTest"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "route53_dns_update_attachment" {
  role       = aws_iam_role.ec2_volume_attach_role.name
  policy_arn = aws_iam_policy.allow_route53_dns_update.arn
}

resource "aws_iam_role_policy_attachment" "ec2_volume_attach_policy_attachment" {
  role       = aws_iam_role.ec2_volume_attach_role.name
  policy_arn = aws_iam_policy.ec2_volume_attach_policy.arn
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "citus_instance_profile" {
  name = "citus-instance-profile-test"
  role = aws_iam_role.ec2_volume_attach_role.name
}

# Create Launch Template for Citus Master
resource "aws_launch_template" "citus_master_test" {
  name_prefix   = "citus-master-test-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    volume_id = var.master_test_volume_id
    coordinator_dns = var.coordinator_dns
    POSTGRES_PASS   = var.postgresql_password
    hosted_zone_id = var.hosted_zone_id
    aws_region = var.aws_region
    PGDATA = var.PGDATA
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.citus_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.citus_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-citus-master"
      Type = "citus-master"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Launch Template for Citus Worker1
resource "aws_launch_template" "citus_worker1_test" {
  name_prefix   = "citus-worker1-test-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

user_data = base64encode(templatefile("${path.module}/user_data_worker1.sh", {
    worker1_volume_id = var.worker1_test_volume_id
    worker1_dns = var.worker1_dns
    coordinator_dns = var.coordinator_dns
    POSTGRES_PASS = var.postgresql_password
    hosted_zone_id = var.hosted_zone_id
    aws_region = var.aws_region
    PGDATA = var.PGDATA
  }))


  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.citus_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.citus_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-citus-worker1"
      Type = "citus-worker1"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Launch Template for Citus Worker2
resource "aws_launch_template" "citus_worker2_test" {
  name_prefix   = "citus-worker2-test-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(templatefile("${path.module}/user_data_worker2.sh", {
    worker2_volume_id = var.worker2_test_volume_id
    worker2_dns = var.worker2_dns
    coordinator_dns = var.coordinator_dns
    POSTGRES_PASS = var.postgresql_password
    hosted_zone_id = var.hosted_zone_id
    aws_region = var.aws_region
    PGDATA = var.PGDATA
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.citus_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.citus_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-citus-worker2"
      Type = "citus-worker2"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Get EBS volume AZs
data "aws_ebs_volume" "master_test_volume" {
  most_recent = true
  filter {
    name   = "volume-id"
    values = [var.master_test_volume_id]
  }
}

data "aws_ebs_volume" "worker1_test_volume" {
  most_recent = true
  filter {
    name   = "volume-id"
    values = [var.worker1_test_volume_id]
  }
}

data "aws_ebs_volume" "worker2_test_volume" {
  most_recent = true
  filter {
    name   = "volume-id"
    values = [var.worker2_test_volume_id]
  }
}

# Get subnet IDs for each AZ
data "aws_subnet" "master_test_subnet" {
  availability_zone = data.aws_ebs_volume.master_test_volume.availability_zone
  vpc_id           = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnet" "worker1_test_subnet" {
  availability_zone = data.aws_ebs_volume.worker1_test_volume.availability_zone
  vpc_id           = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnet" "worker2_test_subnet" {
  availability_zone = data.aws_ebs_volume.worker2_test_volume.availability_zone
  vpc_id           = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Create Auto Scaling Group for Citus Master
resource "aws_autoscaling_group" "citus_master_test_asg" {
  name                = "citus-master-test-ASG"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [data.aws_subnet.master_test_subnet.id]

  launch_template {
    id      = aws_launch_template.citus_master_test.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-citus-master-test-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Type"
    value               = "test-key"
    propagate_at_launch = true
  }
}

# Create Auto Scaling Group for Citus Worker1
resource "aws_autoscaling_group" "citus_worker1_test_asg" {
  name                = "citus-worker1-test-ASG"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [data.aws_subnet.worker1_test_subnet.id]

  launch_template {
    id      = aws_launch_template.citus_worker1_test.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-citus-worker1-test-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Type"
    value               = "test-key"
    propagate_at_launch = true
  }
}

# Create Auto Scaling Group for Citus Worker2
resource "aws_autoscaling_group" "citus_worker2_test_asg" {
  name                = "citus-worker2-test-ASG"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [data.aws_subnet.worker2_test_subnet.id]

  launch_template {
    id      = aws_launch_template.citus_worker2_test.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-citus-worker2-test-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Type"
    value               = "test-key"
    propagate_at_launch = true
  }
} 