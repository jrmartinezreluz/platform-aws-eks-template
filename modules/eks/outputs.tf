output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "oidc_issuer" {
  value = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}

output "kms_key_arn" {
  value = aws_kms_key.eks.arn
}

output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi.arn
}

output "external_secrets_role_arn" {
  value = aws_iam_role.eso.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "fluent_bit_role_arn" {
  value = aws_iam_role.fluent_bit.arn
}

output "kyverno_role_arn" {
  value = aws_iam_role.kyverno.arn
}
