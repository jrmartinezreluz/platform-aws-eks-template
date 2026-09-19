variable "cluster_role" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "enable_efs" {
  type    = bool
  default = false
}
variable "node_security_group_id" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
