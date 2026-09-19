variable "repositories" {
  type        = list(string)
  description = "Neutral ECR names, e.g. hospitality-booking/frontend"
}

variable "tags" {
  type    = map(string)
  default = {}
}
