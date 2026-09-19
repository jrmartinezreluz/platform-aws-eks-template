variable "cluster_role" {
  type        = string
  description = "nonprod or prod"
  validation {
    condition     = contains(["nonprod", "prod"], var.cluster_role)
    error_message = "cluster_role must be nonprod or prod."
  }
}

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type    = number
  default = 3
}

variable "nat_gateway_strategy" {
  type        = string
  description = "single (cost-conscious) or per_az (HA)"
  default     = "single"
  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_strategy)
    error_message = "nat_gateway_strategy must be single or per_az."
  }
}

variable "enable_vpc_endpoints" {
  type    = bool
  default = true
}

variable "interface_endpoint_services" {
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr", "sts", "secretsmanager", "logs", "ec2", "ssm", "ssmmessages", "ec2messages"]
  description = "Interface endpoints when enable_vpc_endpoints is true. MODE B may pass a shorter list."
}

variable "tags" {
  type    = map(string)
  default = {}
}
