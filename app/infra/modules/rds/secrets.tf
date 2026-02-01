# -----------------------------------------------------------------------------
# Secrets Manager for RDS Connection
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "rds" {
  name        = "${var.project}/${var.environment}/rds/credentials"
  description = "RDS PostgreSQL connection credentials for ${var.environment} environment"

  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name        = "${var.project}-${var.environment}-rds-secret"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
    # 接続文字列も含める
    connection_string = "postgresql://${aws_db_instance.main.username}:${random_password.master.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  })
}
