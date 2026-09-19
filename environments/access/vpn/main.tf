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

variable "wireguard_client_cidr" {
  type    = string
  default = "10.100.0.0/24"
}

variable "allowed_udp_cidrs" {
  type    = list(string)
  default = []
}

data "terraform_remote_state" "access_network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/access/network/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpn" {
  source                = "../../../modules/access-vpn"
  vpc_id                = data.terraform_remote_state.access_network.outputs.vpc_id
  subnet_id             = data.terraform_remote_state.access_network.outputs.public_subnet_ids[0]
  vpc_cidr              = data.terraform_remote_state.access_network.outputs.vpc_cidr
  wireguard_client_cidr = var.wireguard_client_cidr
  allowed_udp_cidrs     = var.allowed_udp_cidrs
}

output "instance_id" { value = module.vpn.instance_id }
output "instance_private_ip" { value = module.vpn.instance_private_ip }
output "eip_public_ip" { value = module.vpn.eip_public_ip }
output "security_group_id" { value = module.vpn.security_group_id }
output "iam_role_arn" { value = module.vpn.iam_role_arn }
