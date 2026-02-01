# -----------------------------------------------------------------------------
# Random Password for RDS Master User
# -----------------------------------------------------------------------------
resource "random_password" "master" {
  length  = 32
  special = true
  # RDS パスワード制約: @, ", / は使用不可
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# Lambda からの接続を許可
resource "aws_vpc_security_group_ingress_rule" "from_lambda" {
  count = var.lambda_security_group_id != "" ? 1 : 0

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.lambda_security_group_id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL from Lambda"

  tags = {
    Name = "from-lambda"
  }
}

# CodeBuild からの接続を許可
resource "aws_vpc_security_group_ingress_rule" "from_codebuild" {
  count = var.codebuild_security_group_id != "" ? 1 : 0

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.codebuild_security_group_id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL from CodeBuild"

  tags = {
    Name = "from-codebuild"
  }
}

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

# -----------------------------------------------------------------------------
# DB Parameter Group
# -----------------------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name   = "${var.project}-${var.environment}-postgres15"
  family = "postgres15"

  # 日本語対応
  parameter {
    name  = "client_encoding"
    value = "UTF8"
  }

  parameter {
    name  = "timezone"
    value = "Asia/Tokyo"
  }

  # ログ設定
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # 1秒以上のクエリをログ出力
  }

  tags = {
    Name        = "${var.project}-${var.environment}-postgres15"
    Environment = var.environment
    Project     = var.project
  }
}

# -----------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-db"

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version

  # Instance
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result
  port     = var.db_port

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Parameter & Option Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project}-${var.environment}-db-final-snapshot-${formatdate("YYYYMMDD-hhmm", timestamp())}"

  # Maintenance
  maintenance_window              = var.maintenance_window
  auto_minor_version_upgrade      = true
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled

  tags = {
    Name        = "${var.project}-${var.environment}-db"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}
