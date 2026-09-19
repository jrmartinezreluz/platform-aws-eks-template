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
  default = "10.10.0.0/16"
}

variable "nat_gateway_strategy" {
  type    = string
  default = "single"
}

variable "enable_vpc_endpoints" {
  type    = bool
  default = true
}

variable "interface_endpoint_services" {
  type    = list(string)
  default = ["ecr.api", "ecr.dkr", "sts"]
}

module "network" {
  source                      = "../../../modules/networking"
  cluster_role                = "nonprod"
  vpc_cidr                    = var.vpc_cidr
  nat_gateway_strategy        = var.nat_gateway_strategy
  enable_vpc_endpoints        = var.enable_vpc_endpoints
  interface_endpoint_services = var.interface_endpoint_services
}

output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
