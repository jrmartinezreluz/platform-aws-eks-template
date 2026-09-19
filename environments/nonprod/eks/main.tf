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

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}

variable "bootstrap_principal_arns" {
  type    = list(string)
  default = []
}

variable "github_org" {
  type    = string
  default = "example-org"
}

variable "github_repos" {
  type    = list(string)
  default = ["example-app", "workflow-github-actions-template"]
}

variable "base_domain" {
  type        = string
  default     = ""
  description = "BASE DOMAIN REQUIRES OPERATOR DECISION"
}

variable "enable_efs" {
  type    = bool
  default = false
}

variable "enable_backup" {
  type    = bool
  default = true
}

variable "create_github_oidc_provider" {
  type    = bool
  default = false
}

locals {
  cluster_name = "eks-nonprod"
  # Pinned 2026-09-07 from aws eks describe-addon-versions --kubernetes-version 1.35
  addon_versions = {
    "vpc-cni"                = "v1.23.0-eksbuild.1"
    "coredns"                = "v1.14.3-eksbuild.16"
    "kube-proxy"             = "v1.35.3-eksbuild.21"
    "aws-ebs-csi-driver"     = "v1.65.0-eksbuild.1"
    "aws-efs-csi-driver"     = "v3.4.2-eksbuild.1"
    "snapshot-controller"    = "v8.6.0-eksbuild.6"
    "eks-pod-identity-agent" = "v1.4.0-eksbuild.2"
  }
  ecr_repos = [
    "hospitality-booking/frontend",
    "hospitality-booking/backend",
    "enterprise-erp/app",
    "workflow-automation/app",
    "platform/admission-test",
  ]
  secret_names = [
    "apps/hospitality-booking/dev/database",
    "apps/hospitality-booking/staging/database",
    "apps/hospitality-booking/uat/database",
    "apps/enterprise-erp/dev/database",
    "apps/enterprise-erp/dev/admin",
    "apps/enterprise-erp/staging/database",
    "apps/enterprise-erp/staging/admin",
    "apps/enterprise-erp/uat/database",
    "apps/enterprise-erp/uat/admin",
    "apps/workflow-automation/dev/environment",
    "apps/workflow-automation/staging/environment",
    "apps/workflow-automation/uat/environment",
    "platform/argocd/github-app",
  ]
}

module "eks" {
  source                       = "../../../modules/eks"
  cluster_role                 = "nonprod"
  cluster_name                 = local.cluster_name
  kubernetes_version           = var.kubernetes_version
  vpc_id                       = var.vpc_id
  subnet_ids                   = var.private_subnet_ids
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true
  bootstrap_principal_arns     = var.bootstrap_principal_arns
  enable_efs_csi               = var.enable_efs
  addon_versions               = local.addon_versions
  addon_configuration_values = {
    "vpc-cni" = jsonencode({
      enableNetworkPolicy = "true"
    })
  }
}

module "node_groups" {
  source             = "../../../modules/node-groups"
  cluster_name       = local.cluster_name
  cluster_arn        = module.eks.cluster_arn
  cluster_role       = "nonprod"
  subnet_ids         = var.private_subnet_ids
  kubernetes_version = var.kubernetes_version
  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      labels         = { workload = "system" }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
    applications = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
      labels         = { workload = "apps" }
    }
  }
}

module "registry" {
  source       = "../../../modules/registry"
  repositories = local.ecr_repos
}

module "iam" {
  source               = "../../../modules/iam"
  cluster_role         = "nonprod"
  github_org           = var.github_org
  github_repos         = var.github_repos
  ecr_repository_arns  = values(module.registry.repository_arns)
  create_oidc_provider = var.create_github_oidc_provider
}

module "storage" {
  source                 = "../../../modules/storage"
  cluster_role           = "nonprod"
  vpc_id                 = var.vpc_id
  private_subnet_ids     = var.private_subnet_ids
  enable_efs             = var.enable_efs
  node_security_group_id = module.eks.cluster_security_group_id
}

module "secret_store" {
  source       = "../../../modules/secret-store"
  secret_names = local.secret_names
}

module "dns" {
  source       = "../../../modules/dns"
  cluster_role = "nonprod"
  base_domain  = var.base_domain
  vpc_id       = var.vpc_id
}

module "observability" {
  source       = "../../../modules/observability"
  cluster_name = local.cluster_name
  cluster_role = "nonprod"
}

module "backup" {
  source         = "../../../modules/backup"
  cluster_role   = "nonprod"
  retention_days = 14
  enable_backup  = var.enable_backup
}

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_ca" {
  value     = module.eks.cluster_ca
  sensitive = true
}
output "oidc_issuer" { value = module.eks.oidc_issuer }
output "ecr_repository_urls" { value = module.registry.repository_urls }
output "ecr_push_role_arn" { value = module.iam.ecr_push_role_arn }
output "efs_id" { value = module.storage.efs_id }
output "route53_zone_id" { value = module.dns.zone_id }
output "backup_vault_name" { value = module.backup.vault_name }
output "external_secrets_role_arn" { value = module.eks.external_secrets_role_arn }
output "cluster_autoscaler_role_arn" { value = module.eks.cluster_autoscaler_role_arn }
output "fluent_bit_role_arn" { value = module.eks.fluent_bit_role_arn }
output "kyverno_role_arn" { value = module.eks.kyverno_role_arn }
