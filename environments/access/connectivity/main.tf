terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket" {
  type        = string
  description = "Terraform state bucket. Supply via tfvars; do not commit the live name."
  default     = "example-org-tfstate-us-east-1"
}

variable "nonprod_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "prod_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "access_network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/access/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "access_vpn" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/access/vpn/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "nonprod_network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/eks/nonprod/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "prod_network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/eks/prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "nonprod_eks" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/eks/nonprod/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  access_vpc_id  = data.terraform_remote_state.access_network.outputs.vpc_id
  access_cidr    = data.terraform_remote_state.access_network.outputs.vpc_cidr
  access_rtb     = data.terraform_remote_state.access_network.outputs.public_route_table_id
  nonprod_vpc_id = data.terraform_remote_state.nonprod_network.outputs.vpc_id
  prod_vpc_id    = data.terraform_remote_state.prod_network.outputs.vpc_id
  vpn_sg         = data.terraform_remote_state.access_vpn.outputs.security_group_id
  common_tags = {
    Environment = "access"
    Platform    = "vpn"
    Component   = "peering"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
  }
}

data "aws_eks_cluster" "nonprod" { name = "eks-nonprod" }
data "aws_eks_cluster" "prod" { name = "eks-prod" }

data "aws_route_tables" "nonprod_private" {
  vpc_id = local.nonprod_vpc_id
  filter {
    name   = "tag:Name"
    values = ["vpc-nonprod-private-*"]
  }
}

data "aws_route_tables" "prod_private" {
  vpc_id = local.prod_vpc_id
  filter {
    name   = "tag:Name"
    values = ["vpc-prod-private-*"]
  }
}

resource "aws_vpc_peering_connection" "access_nonprod" {
  vpc_id      = local.access_vpc_id
  peer_vpc_id = local.nonprod_vpc_id
  auto_accept = true
  tags        = merge(local.common_tags, { Name = "pcx-access-nonprod" })
}

resource "aws_vpc_peering_connection" "access_prod" {
  vpc_id      = local.access_vpc_id
  peer_vpc_id = local.prod_vpc_id
  auto_accept = true
  tags        = merge(local.common_tags, { Name = "pcx-access-prod" })
}

resource "aws_vpc_peering_connection" "nonprod_prod" {
  vpc_id      = local.nonprod_vpc_id
  peer_vpc_id = local.prod_vpc_id
  auto_accept = true
  tags        = merge(local.common_tags, { Name = "pcx-nonprod-prod" })
}

resource "aws_vpc_peering_connection_options" "access_nonprod" {
  vpc_peering_connection_id = aws_vpc_peering_connection.access_nonprod.id
  requester { allow_remote_vpc_dns_resolution = true }
  accepter { allow_remote_vpc_dns_resolution = true }
}

resource "aws_vpc_peering_connection_options" "access_prod" {
  vpc_peering_connection_id = aws_vpc_peering_connection.access_prod.id
  requester { allow_remote_vpc_dns_resolution = true }
  accepter { allow_remote_vpc_dns_resolution = true }
}

resource "aws_vpc_peering_connection_options" "nonprod_prod" {
  vpc_peering_connection_id = aws_vpc_peering_connection.nonprod_prod.id
  requester { allow_remote_vpc_dns_resolution = true }
  accepter { allow_remote_vpc_dns_resolution = true }
}

resource "aws_route" "access_to_nonprod" {
  route_table_id            = local.access_rtb
  destination_cidr_block    = var.nonprod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.access_nonprod.id
}

resource "aws_route" "access_to_prod" {
  route_table_id            = local.access_rtb
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.access_prod.id
}

resource "aws_route" "nonprod_to_access" {
  for_each                  = toset(data.aws_route_tables.nonprod_private.ids)
  route_table_id            = each.value
  destination_cidr_block    = local.access_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.access_nonprod.id
}

resource "aws_route" "nonprod_to_prod" {
  for_each                  = toset(data.aws_route_tables.nonprod_private.ids)
  route_table_id            = each.value
  destination_cidr_block    = var.prod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nonprod_prod.id
}

resource "aws_route" "prod_to_access" {
  for_each                  = toset(data.aws_route_tables.prod_private.ids)
  route_table_id            = each.value
  destination_cidr_block    = local.access_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.access_prod.id
}

resource "aws_route" "prod_to_nonprod" {
  for_each                  = toset(data.aws_route_tables.prod_private.ids)
  route_table_id            = each.value
  destination_cidr_block    = var.nonprod_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nonprod_prod.id
}

# Cluster SG: API 443 from vpn-access (SNAT) and from the peer VPC CIDR for GitOps.
resource "aws_vpc_security_group_ingress_rule" "nonprod_api_from_vpn_sg" {
  security_group_id            = data.aws_eks_cluster.nonprod.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = local.vpn_sg
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "vpn-access WireGuard SNAT"
  depends_on                   = [aws_vpc_peering_connection_options.access_nonprod]
}

resource "aws_vpc_security_group_ingress_rule" "nonprod_api_from_access_cidr" {
  security_group_id = data.aws_eks_cluster.nonprod.vpc_config[0].cluster_security_group_id
  cidr_ipv4         = local.access_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "vpc-access CIDR fallback"
}

resource "aws_vpc_security_group_ingress_rule" "prod_api_from_vpn_sg" {
  security_group_id            = data.aws_eks_cluster.prod.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = local.vpn_sg
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "vpn-access WireGuard SNAT"
  depends_on                   = [aws_vpc_peering_connection_options.access_prod]
}

resource "aws_vpc_security_group_ingress_rule" "prod_api_from_access_cidr" {
  security_group_id = data.aws_eks_cluster.prod.vpc_config[0].cluster_security_group_id
  cidr_ipv4         = local.access_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "vpc-access CIDR fallback"
}

resource "aws_vpc_security_group_ingress_rule" "prod_api_from_nonprod_cidr" {
  security_group_id = data.aws_eks_cluster.prod.vpc_config[0].cluster_security_group_id
  cidr_ipv4         = var.nonprod_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Argo CD hub on eks-nonprod"
}

# IRSA for Argo CD hub to authenticate to eks-prod (no operator kubeconfig).
locals {
  oidc_issuer_host  = replace(data.terraform_remote_state.nonprod_eks.outputs.oidc_issuer, "https://", "")
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_host}"
}

data "aws_iam_policy_document" "argocd_irsa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-application-controller",
        "system:serviceaccount:argocd:argocd-server",
      ]
    }
  }
}

resource "aws_iam_role" "argocd_hub" {
  name               = "eks-nonprod-argocd"
  assume_role_policy = data.aws_iam_policy_document.argocd_irsa.json
  tags               = merge(local.common_tags, { Name = "eks-nonprod-argocd", Component = "gitops" })
}

resource "aws_eks_access_entry" "argocd_prod" {
  cluster_name  = "eks-prod"
  principal_arn = aws_iam_role.argocd_hub.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "argocd_prod_admin" {
  cluster_name  = "eks-prod"
  principal_arn = aws_iam_role.argocd_hub.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.argocd_prod]
}

output "peering_ids" {
  value = {
    access_nonprod = aws_vpc_peering_connection.access_nonprod.id
    access_prod    = aws_vpc_peering_connection.access_prod.id
    nonprod_prod   = aws_vpc_peering_connection.nonprod_prod.id
  }
}

output "argocd_hub_role_arn" {
  value = aws_iam_role.argocd_hub.arn
}

resource "aws_eks_access_entry" "vpn_nonprod" {
  cluster_name  = "eks-nonprod"
  principal_arn = data.terraform_remote_state.access_vpn.outputs.iam_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "vpn_nonprod_admin" {
  cluster_name  = "eks-nonprod"
  principal_arn = data.terraform_remote_state.access_vpn.outputs.iam_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.vpn_nonprod]
}

resource "aws_eks_access_entry" "vpn_prod" {
  cluster_name  = "eks-prod"
  principal_arn = data.terraform_remote_state.access_vpn.outputs.iam_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "vpn_prod_admin" {
  cluster_name  = "eks-prod"
  principal_arn = data.terraform_remote_state.access_vpn.outputs.iam_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.vpn_prod]
}
