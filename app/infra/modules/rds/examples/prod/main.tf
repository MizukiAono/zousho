# -----------------------------------------------------------------------------
# RDS Module - Production Environment Example
# -----------------------------------------------------------------------------
# この例は本番環境向けの推奨設定を示しています。
# 可用性、信頼性、セキュリティを優先した構成です。
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
      Environment = "prod"
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
#   environment = "prod"
#   vpc_cidr    = "10.1.0.0/16"
# }

# -----------------------------------------------------------------------------
# Lambda Module（例として記載）
# -----------------------------------------------------------------------------
# module "lambda" {
#   source = "../../lambda"
#
#   project     = "zousho"
#   environment = "prod"
#   vpc_id      = module.vpc.vpc_id
#   # ...
# }

# -----------------------------------------------------------------------------
# CodeBuild Module（例として記載）
# -----------------------------------------------------------------------------
# module "codebuild" {
#   source = "../../codebuild"
#
#   project     = "zousho"
#   environment = "prod"
#   vpc_id      = module.vpc.vpc_id
#   # ...
# }

# -----------------------------------------------------------------------------
# RDS Module - Production Configuration
# -----------------------------------------------------------------------------
module "rds" {
  source = "../.."

  project     = "zousho"
  environment = "prod"

  # ネットワーク設定
  # vpc_id             = module.vpc.vpc_id
  # private_subnet_ids = module.vpc.private_subnet_ids

  # データベース設定
  db_name     = "zousho"
  db_username = "postgres"
  db_port     = 5432

  # インスタンス設定（本番環境）
  instance_class        = "db.t3.small" # より高性能なインスタンス
  allocated_storage     = 100           # 初期ストレージ 100GB
  max_allocated_storage = 500           # 自動スケーリング上限 500GB
  engine_version        = "15.5"

  # 高可用性設定
  # 注意: Multi-AZ を有効にするとコストが約2倍になります
  # 予算と可用性要件に応じて設定してください
  multi_az = false # 小規模システムの場合は false でも可

  # 削除保護（本番環境必須）
  deletion_protection = true  # 誤削除を防止
  skip_final_snapshot = false # 削除時に必ず最終スナップショットを作成

  # バックアップ設定（本番環境推奨）
  backup_retention_period = 30                 # 30日間保持
  backup_window           = "18:00-19:00"      # JST 03:00-04:00
  maintenance_window      = "sun:19:00-sun:20:00" # JST 日曜 04:00-05:00

  # ログ設定（パフォーマンス考慮）
  log_statement = "ddl" # DDL のみログ出力（CREATE, ALTER, DROP など）

  # モニタリング設定（本番環境推奨）
  performance_insights_enabled    = true # クエリパフォーマンス分析
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # セキュリティグループ設定
  # Lambda からの接続を許可
  # lambda_security_group_id = module.lambda.security_group_id

  # CodeBuild（DB マイグレーション）からの接続を許可
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

output "secret_arn" {
  description = "Secrets Manager シークレット ARN"
  value       = module.rds.secret_arn
  sensitive   = true
}

output "secret_name" {
  description = "Secrets Manager シークレット名"
  value       = module.rds.secret_name
}

output "rds_security_group_id" {
  description = "RDS セキュリティグループ ID（Lambda/CodeBuild に設定）"
  value       = module.rds.rds_security_group_id
}

# -----------------------------------------------------------------------------
# 本番環境運用ガイド
# -----------------------------------------------------------------------------
# 1. 接続情報の確認
#    aws secretsmanager get-secret-value \
#      --secret-id zousho/prod/rds/credentials \
#      --query SecretString \
#      --output text | jq .
#
# 2. バックアップの確認
#    aws rds describe-db-snapshots \
#      --db-instance-identifier zousho-prod-db
#
# 3. Performance Insights の確認
#    AWS マネジメントコンソール > RDS > Performance Insights
#
# 4. CloudWatch Logs の確認
#    aws logs tail /aws/rds/instance/zousho-prod-db/postgresql --follow
#
# 5. 削除時の注意事項
#    deletion_protection = true のため、削除前に以下の手順が必要:
#    a. deletion_protection = false に変更して terraform apply
#    b. terraform destroy を実行
#    c. 最終スナップショットが自動作成される
#
# 6. スナップショットからの復元
#    aws rds restore-db-instance-from-db-snapshot \
#      --db-instance-identifier zousho-prod-db-restored \
#      --db-snapshot-identifier <snapshot-id>
