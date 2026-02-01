# -----------------------------------------------------------------------------
# RDS Instance Outputs
# -----------------------------------------------------------------------------
output "db_instance_id" {
  description = "RDS インスタンス ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS インスタンス ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS インスタンス エンドポイント"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "RDS インスタンス ホスト名"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS インスタンス ポート番号"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "データベース名"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "マスターユーザー名"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "rds_security_group_id" {
  description = "RDS セキュリティグループ ID"
  value       = aws_security_group.rds.id
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secret_arn" {
  description = "Secrets Manager シークレット ARN"
  value       = aws_secretsmanager_secret.rds.arn
}

output "secret_name" {
  description = "Secrets Manager シークレット名"
  value       = aws_secretsmanager_secret.rds.name
}
