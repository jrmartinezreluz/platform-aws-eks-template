output "node_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "node_group_names" {
  value = [for g in aws_eks_node_group.this : g.node_group_name]
}
