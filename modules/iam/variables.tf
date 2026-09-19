variable "cluster_role" { type = string }
variable "github_org" { type = string }
variable "github_repos" {
  type        = list(string)
  description = "Repos allowed to assume ECR push roles (current GitHub names)"
}
variable "github_environments" {
  type    = list(string)
  default = ["dev", "staging", "uat", "production"]
}
variable "ecr_repository_arns" { type = list(string) }
variable "create_oidc_provider" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
