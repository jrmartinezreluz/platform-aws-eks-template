terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "vpc_cidr" { type = string }
variable "wireguard_client_cidr" { type = string }
variable "wireguard_listen_port" {
  type    = number
  default = 51820
}
variable "allowed_udp_cidrs" {
  type        = list(string)
  description = "Sources allowed to reach WireGuard UDP. Prefer operator /32."
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

locals {
  common_tags = merge(var.tags, {
    Environment = "access"
    Platform    = "vpn"
    Component   = "wireguard"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
    Name        = "vpn-access"
  })
}

data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpn" {
  name               = "vpn-access"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.vpn.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "vpn_secrets" {
  statement {
    sid = "WireGuardClientConfig"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:TagResource",
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:platform/access/*",
    ]
  }
  statement {
    sid = "EksKubeconfig"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpn_secrets" {
  name   = "wireguard-secret-bootstrap"
  role   = aws_iam_role.vpn.id
  policy = data.aws_iam_policy_document.vpn_secrets.json
}

resource "aws_iam_instance_profile" "vpn" {
  name = "vpn-access"
  role = aws_iam_role.vpn.name
  tags = local.common_tags
}

resource "aws_security_group" "vpn" {
  name        = "vpn-access"
  description = "WireGuard UDP only; no SSH"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "wireguard" {
  for_each          = toset(var.allowed_udp_cidrs)
  security_group_id = aws_security_group.vpn.id
  cidr_ipv4         = each.value
  from_port         = var.wireguard_listen_port
  to_port           = var.wireguard_listen_port
  ip_protocol       = "udp"
  description       = "WireGuard"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.vpn.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "vpn" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.vpn.name
  vpc_security_group_ids = [aws_security_group.vpn.id]
  source_dest_check      = false
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf install -y wireguard-tools iptables
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
  EOF
  tags      = local.common_tags
}

resource "aws_eip" "vpn" {
  domain   = "vpc"
  instance = aws_instance.vpn.id
  tags     = merge(local.common_tags, { Name = "vpn-access-eip" })
}

output "instance_id" { value = aws_instance.vpn.id }
output "instance_private_ip" { value = aws_instance.vpn.private_ip }
output "eip_public_ip" { value = aws_eip.vpn.public_ip }
output "security_group_id" { value = aws_security_group.vpn.id }
output "iam_role_arn" { value = aws_iam_role.vpn.arn }
