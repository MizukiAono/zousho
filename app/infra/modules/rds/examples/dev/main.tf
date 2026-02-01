# -----------------------------------------------------------------------------
# RDS Module - Development Environment Example
# -----------------------------------------------------------------------------
# この例は開発環境向けの推奨設定を示しています。
# コスト最適化とイテレーション速度を優先した構成です。
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "zousho"
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# VPC Module（例として記載）
# 実際には既存の VPC モジュールを使用してください
# -----------------------------------------------------------------------------
# module "vpc" {
#   source = "../../vpc"
#
#   project     = "zousho"
#   environment = "dev"
#   vpc_cidr    = "10.0.0.0/16"
# }

# -----------------------------------------------------------------------------
# RDS Module - Dev Configuration
# -----------------------------------------------------------------------------
module "rds" {
  source = "../.."

  project     = "zousho"
  environment = "dev"

  # ネットワーク設定
  # vpc_id             = module.vpc.vpc_id
  # private_subnet_ids = module.vpc.private_subnet_ids

  # データベース設定
  db_name     = "zousho"
  db_username = "postgres"
  db_port     = 5432

  # インスタンス設定（コスト最適化）
  instance_class    = "db.t3.micro" # 最小インスタンス
  allocated_storage = 20            # 最小ストレージ
  multi_az          = false         # シングル AZ でコスト削減

  # 削除設定（開発環境向け）
  deletion_protection = false # terraform destroy を許可
  skip_final_snapshot = true  # 削除時にスナップショット不要

  # バックアップ設定（最小限）
  backup_retention_period = 1 # 1日間のみ保持

  # ログ設定（詳細なデバッグ情報）
  log_statement = "all" # すべての SQL 文をログ出力

  # モニタリング設定
  performance_insights_enabled    = false # コスト削減のため無効
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # セキュリティグループ設定
  # Lambda モジュール作成後に設定
  # lambda_security_group_id = module.lambda.security_group_id

  # CodeBuild モジュール作成後に設定
  # codebuild_security_group_id = module.codebuild.security_group_id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "db_endpoint" {
  description = "RDS エンドポイント"
  value       = module.rds.db_instance_endpoint
}

output "db_address" {
  description = "RDS ホスト名"
  value       = module.rds.db_instance_address
}

output "secret_name" {
  description = "Secrets Manager シークレット名"
  value       = module.rds.secret_name
}

output "rds_security_group_id" {
  description = "RDS セキュリティグループ ID"
  value       = module.rds.rds_security_group_id
}

# -----------------------------------------------------------------------------
# 接続情報の確認方法
# -----------------------------------------------------------------------------
# AWS CLI で接続情報を取得:
#
# aws secretsmanager get-secret-value \
#   --secret-id zousho/dev/rds/credentials \
#   --query SecretString \
#   --output text | jq .
#
# 接続文字列を取得:
#
# aws secretsmanager get-secret-value \
#   --secret-id zousho/dev/rds/credentials \
#   --query SecretString \
#   --output text | jq -r .connection_string
