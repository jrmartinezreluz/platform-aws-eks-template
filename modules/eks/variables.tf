variable "cluster_role" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "AWS EKS cluster name, e.g. eks-nonprod"
}

variable "kubernetes_version" {
  type        = string
  description = "Confirm with aws eks describe-cluster-versions before apply"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for control plane ENIs and nodes"
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type        = bool
  default     = false
  description = "Private-only is the platform default. Operator access is vpc-access WireGuard."
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  default     = []
  description = "Unused when endpoint_public_access is false."
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "bootstrap_principal_arns" {
  type        = list(string)
  default     = []
  description = "IAM principals granted cluster admin via access entries"
}

variable "addon_versions" {
  type        = map(string)
  default     = {}
  description = "Optional pins. Empty = EKS default compatible version. Query describe-addon-versions before apply."
}

variable "addon_configuration_values" {
  type        = map(string)
  default     = {}
  description = "Optional JSON configurationValues keyed by add-on name (e.g. vpc-cni). Unset add-ons keep AWS defaults."
}

variable "enable_pod_identity_agent" {
  type    = bool
  default = true
}

variable "enable_efs_csi" {
  type    = bool
  default = false
}

variable "enable_snapshot_controller" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
