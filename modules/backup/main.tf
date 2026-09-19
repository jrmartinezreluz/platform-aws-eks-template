terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "cluster_role" { type = string }
variable "retention_days" {
  type    = number
  default = 14
}
variable "enable_backup" {
  type        = bool
  default     = true
  description = "Set false when the identity cannot create AWS Backup vaults (sandbox PassRole/KMS limits)."
}
variable "enable_selection" {
  type        = bool
  default     = false
  description = "Requires iam:PassRole to backup.amazonaws.com on role backup-<role>."
}
variable "not_resources" {
  type        = list(string)
  default     = []
  description = "ARNs excluded from the tagged selection (e.g. EFS already on automatic backup)."
}
variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.cluster_role
    Platform    = "eks"
    Component   = "backup"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
  })
}

resource "aws_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0
  name  = "backup-${var.cluster_role}"
  tags  = merge(local.common_tags, { Name = "backup-${var.cluster_role}" })
}

resource "aws_backup_plan" "daily" {
  count = var.enable_backup ? 1 : 0
  name  = "backup-${var.cluster_role}-daily"
  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 5 * * ? *)"
    lifecycle {
      delete_after = var.retention_days
    }
  }
  tags = local.common_tags
}

data "aws_iam_policy_document" "backup" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  count              = var.enable_backup ? 1 : 0
  name               = "backup-${var.cluster_role}"
  assume_role_policy = data.aws_iam_policy_document.backup.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.enable_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = var.enable_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "tagged" {
  count         = var.enable_backup && var.enable_selection ? 1 : 0
  name          = "tagged-${var.cluster_role}"
  iam_role_arn  = aws_iam_role.backup[0].arn
  plan_id       = aws_backup_plan.daily[0].id
  not_resources = var.not_resources
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = var.cluster_role
  }
}

output "vault_name" {
  value = try(aws_backup_vault.this[0].name, null)
}

output "plan_id" {
  value = try(aws_backup_plan.daily[0].id, null)
}
