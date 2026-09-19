terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "secret_names" {
  type        = list(string)
  description = "Secrets Manager names (metadata only, no values)"
}

variable "recovery_window_in_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_secretsmanager_secret" "this" {
  for_each                = toset(var.secret_names)
  name                    = each.value
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(var.tags, {
    Platform   = "eks"
    Component  = "secret-store"
    ManagedBy  = "terraform"
    Repository = "platform-aws-eks"
    Name       = each.value
  })
}

output "secret_arns" {
  value = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}
