# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------
variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名（dev/prod）"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod"
  }
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs（RDS配置用）"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# RDS Instance Variables
# -----------------------------------------------------------------------------
variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "zousho"
}

variable "db_username" {
  description = "マスターユーザー名"
  type        = string
  default     = "postgres"
}

variable "db_port" {
  description = "データベースポート番号"
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "RDS インスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "割り当てストレージ容量（GB）"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "自動ストレージスケーリングの最大容量（GB）"
  type        = number
  default     = 100
}

variable "engine_version" {
  description = "PostgreSQL エンジンバージョン"
  type        = string
  default     = "15.5"
}

variable "multi_az" {
  description = "Multi-AZ 構成の有効化"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "バックアップ保持期間（日数）"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "バックアップ実行時間（UTC）"
  type        = string
  default     = "18:00-19:00" # JST 03:00-04:00
}

variable "maintenance_window" {
  description = "メンテナンス実行時間（UTC）"
  type        = string
  default     = "sun:19:00-sun:20:00" # JST 日曜 04:00-05:00
}

variable "deletion_protection" {
  description = "削除保護の有効化"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "削除時に最終スナップショットをスキップ"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Security Variables
# -----------------------------------------------------------------------------
variable "lambda_security_group_id" {
  description = "Lambda セキュリティグループ ID（接続許可用）"
  type        = string
  default     = ""
}

variable "codebuild_security_group_id" {
  description = "CodeBuild セキュリティグループ ID（接続許可用）"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Monitoring Variables
# -----------------------------------------------------------------------------
variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatch Logs へ出力するログの種類"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "performance_insights_enabled" {
  description = "Performance Insights の有効化"
  type        = bool
  default     = false
}
