output "efs_id" {
  value = try(aws_efs_file_system.this[0].id, null)
}
