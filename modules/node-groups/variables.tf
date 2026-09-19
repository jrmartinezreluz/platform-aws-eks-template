variable "cluster_name" { type = string }
variable "cluster_arn" {
  type        = string
  description = "Cluster ARN; interpolating this forces node groups to wait for the cluster without waiting for add-ons."
}
variable "cluster_role" { type = string }
variable "subnet_ids" { type = list(string) }
variable "kubernetes_version" { type = string }

variable "node_groups" {
  description = "Map of managed node groups (system, applications)"
  type = map(object({
    instance_types = list(string)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
