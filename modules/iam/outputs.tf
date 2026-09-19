output "github_oidc_provider_arn" {
  value = try(aws_iam_openid_connect_provider.github[0].arn, null)
}

output "ecr_push_role_arn" {
  value = aws_iam_role.ecr_push.arn
}
