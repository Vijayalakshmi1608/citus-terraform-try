resource "aws_ebs_volume" "master_citus_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "master-citus"
  }
}

resource "aws_ebs_volume" "worker_citus_1_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "worker-citus-1"
  }
}

resource "aws_ebs_volume" "worker_citus_2_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "worker-citus-2"
  }
} 


resource "aws_ebs_volume" "master_citus_replica_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "master-citus-replica"
  }
}

resource "aws_ebs_volume" "worker_citus_1_replica_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "worker-citus-1-replica"
  }
}

resource "aws_ebs_volume" "worker_citus_2_replica_test" {
  availability_zone = var.availability_zone
  size              = 100
  iops              = 3000
  type              = "gp3"
  tags = {
    Name = "worker-citus-2-replica"
  }
} 
