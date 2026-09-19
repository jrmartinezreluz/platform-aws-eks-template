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

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

module "network" {
  source   = "../../../modules/access-network"
  vpc_cidr = var.vpc_cidr
}

output "vpc_id" { value = module.network.vpc_id }
output "vpc_cidr" { value = module.network.vpc_cidr }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "public_route_table_id" { value = module.network.public_route_table_id }
