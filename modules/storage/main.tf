locals {
  common_tags = merge(var.tags, {
    Environment = var.cluster_role
    Platform    = "eks"
    Component   = "storage"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
  })
}

resource "aws_efs_file_system" "this" {
  count           = var.enable_efs ? 1 : 0
  encrypted       = true
  throughput_mode = "bursting"
  tags            = merge(local.common_tags, { Name = "efs-${var.cluster_role}", Backup = var.cluster_role })
}

resource "aws_security_group" "efs" {
  count       = var.enable_efs ? 1 : 0
  name        = "efs-${var.cluster_role}"
  description = "EFS NFS from cluster nodes"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.node_security_group_id != "" ? [var.node_security_group_id] : []
    content {
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "NFS from cluster security group"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "efs-${var.cluster_role}" })
}

resource "aws_efs_mount_target" "this" {
  count           = var.enable_efs ? length(var.private_subnet_ids) : 0
  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}
