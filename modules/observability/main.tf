terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "cluster_name" { type = string }
variable "cluster_role" { type = string }
variable "retention_in_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_cloudwatch_log_group" "platform" {
  for_each          = toset(["application", "dataplane", "host"])
  name              = "/eks/${var.cluster_name}/${each.key}"
  retention_in_days = var.retention_in_days
  tags = merge(var.tags, {
    Environment = var.cluster_role
    Platform    = "eks"
    Component   = "observability"
    ManagedBy   = "terraform"
    Repository  = "platform-aws-eks-template"
  })
}

output "log_group_names" {
  value = [for g in aws_cloudwatch_log_group.platform : g.name]
}
