data "aws_iam_policy_document" "nodes" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.cluster_role
    Platform    = "eks"
    Component   = "node-groups"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
  })
}

resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-nodes"
  assume_role_policy = data.aws_iam_policy_document.nodes.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

resource "aws_launch_template" "this" {
  for_each    = var.node_groups
  name_prefix = "${var.cluster_name}-${each.key}-"
  description = "Encrypted root volume and IMDSv2 for ${var.cluster_name} ${each.key}"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-${each.key}" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-${each.key}" })
  }

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-${each.key}" })
}

resource "aws_eks_node_group" "this" {
  for_each        = var.node_groups
  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value.instance_types
  ami_type        = each.value.ami_type
  capacity_type   = each.value.capacity_type
  version         = var.kubernetes_version

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = aws_launch_template.this[each.key].latest_version
  }

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
  tags = merge(local.common_tags, {
    Name       = "${var.cluster_name}-${each.key}"
    ClusterArn = var.cluster_arn
  })
}
