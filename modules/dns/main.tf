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
variable "base_domain" {
  type        = string
  default     = ""
  description = "BASE DOMAIN REQUIRES OPERATOR DECISION. Empty skips zone create."
}
variable "private_zone" {
  type    = bool
  default = true
}
variable "vpc_id" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_route53_zone" "this" {
  count = var.base_domain == "" ? 0 : 1
  name  = var.base_domain
  dynamic "vpc" {
    for_each = var.private_zone && var.vpc_id != "" ? [var.vpc_id] : []
    content {
      vpc_id = vpc.value
    }
  }
  tags = merge(var.tags, {
    Environment = var.cluster_role
    Platform    = "eks"
    Component   = "dns"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
    Name        = var.base_domain
  })
}

output "zone_id" {
  value = try(aws_route53_zone.this[0].zone_id, null)
}
