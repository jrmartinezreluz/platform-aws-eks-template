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

data "terraform_remote_state" "nonprod_eks" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/eks/nonprod/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "prod_eks" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/eks/prod/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  tags = {
    Platform  = "eks"
    ManagedBy = "terraform"
  }
}

# Vaults + tagged selections after iam:PassRole to backup.amazonaws.com on backup-* roles.
# EFS automatic backup remains aws_efs_backup_policy.prod.
module "backup_nonprod" {
  source           = "../../../modules/backup"
  cluster_role     = "nonprod"
  enable_backup    = true
  enable_selection = true
  retention_days   = 14
  tags             = local.tags
}

module "backup_prod" {
  source           = "../../../modules/backup"
  cluster_role     = "prod"
  enable_backup    = true
  enable_selection = true
  retention_days   = 35
  # EFS already uses aws/efs/automatic-backup-vault; tag Backup=prod would otherwise duplicate it.
  not_resources = []
  tags          = local.tags
}

module "velero_nonprod" {
  source         = "../../../modules/velero"
  cluster_role   = "nonprod"
  cluster_name   = "eks-nonprod"
  oidc_issuer    = data.terraform_remote_state.nonprod_eks.outputs.oidc_issuer
  bucket_name    = "example-org-velero-nonprod"
  retention_days = 14
  tags           = local.tags
}

module "velero_prod" {
  source         = "../../../modules/velero"
  cluster_role   = "prod"
  cluster_name   = "eks-prod"
  oidc_issuer    = data.terraform_remote_state.prod_eks.outputs.oidc_issuer
  bucket_name    = "example-org-velero-prod"
  retention_days = 35
  tags           = local.tags
}

resource "aws_efs_backup_policy" "prod" {
  count          = try(data.terraform_remote_state.prod_eks.outputs.efs_id, null) != null ? 1 : 0
  file_system_id = data.terraform_remote_state.prod_eks.outputs.efs_id
  backup_policy {
    status = "ENABLED"
  }
}

output "backup_vault_nonprod" { value = module.backup_nonprod.vault_name }
output "backup_vault_prod" { value = module.backup_prod.vault_name }
output "velero_bucket_nonprod" { value = module.velero_nonprod.bucket_name }
output "velero_bucket_prod" { value = module.velero_prod.bucket_name }
output "velero_role_nonprod" { value = module.velero_nonprod.role_arn }
output "velero_role_prod" { value = module.velero_prod.role_arn }
