# -----------------------------------------------------------------------------
# Cognito Module - Development Environment Example
# -----------------------------------------------------------------------------
# この例は開発環境向けの推奨設定を示しています。
# 開発効率を優先しつつ、セキュリティのベストプラクティスを適用した構成です。
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
# Cognito Module - Dev Configuration
# -----------------------------------------------------------------------------
module "cognito" {
  source = "../.."

  user_pool_name  = "zousho-dev-user-pool"
  app_client_name = "zousho-dev-app-client"

  # ユーザー名設定
  username_attributes      = ["email"]
  username_case_sensitive  = false
  auto_verified_attributes = ["email"]

  # MFA設定（開発環境では任意）
  mfa_configuration = "OPTIONAL"

  # パスワードポリシー（開発環境向け：やや緩め）
  password_policy = {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false # 開発環境では記号を任意に
    temporary_password_validity_days = 7
  }

  # アカウント回復設定
  account_recovery_mechanism = {
    name     = "verified_email"
    priority = 1
  }

  # OAuth設定
  oauth_flows         = ["code"]
  oauth_flows_enabled = true
  oauth_scopes        = ["openid", "email", "profile"]

  # コールバックURL（ローカル開発用）
  callback_urls = [
    "http://localhost:5173/callback", # Frontend (Vite)
    "http://localhost:3000/callback"  # Admin (React Admin)
  ]

  # ログアウトURL
  logout_urls = [
    "http://localhost:5173/",
    "http://localhost:3000/"
  ]

  # 認証フロー
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH" # 開発環境では簡易認証も許可
  ]

  # トークン有効期限（開発環境：長めに設定）
  token_validity = {
    refresh_token_validity = 30 # 30日
    access_token_validity  = 60 # 60分
    id_token_validity      = 60 # 60分
  }

  token_validity_units = {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  # セキュリティ設定
  generate_client_secret                        = false # SPA用
  enable_token_revocation                       = true
  prevent_user_existence_errors                 = "ENABLED"
  enable_propagate_additional_user_context_data = false

  # 読み書き可能な属性
  read_attributes = [
    "email",
    "email_verified",
    "name"
  ]

  write_attributes = [
    "email",
    "name"
  ]

  # サポートする認証プロバイダー
  supported_identity_providers = ["COGNITO"]

  # ユーザーグループ
  user_groups = [
    {
      name        = "admin"
      description = "管理者グループ - すべての操作が可能"
      precedence  = 1
    },
    {
      name        = "user"
      description = "一般ユーザーグループ - 基本的な操作が可能"
      precedence  = 10
    }
  ]

  # カスタム属性（例）
  schemas = [
    {
      name                = "department"
      attribute_data_type = "String"
      mutable             = true
      required            = false
      min_length          = 1
      max_length          = 100
    }
  ]

  # ドメイン設定（開発環境用）
  domain = "zousho-dev-auth"

  tags = {
    Environment = "dev"
    Project     = "zousho"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool Endpoint"
  value       = module.cognito.user_pool_endpoint
}

output "app_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.app_client_id
}

output "domain" {
  description = "Cognito User Pool Domain"
  value       = module.cognito.domain
}

output "user_groups" {
  description = "Cognito User Groups"
  value       = module.cognito.user_groups
}

# -----------------------------------------------------------------------------
# 使用例
# -----------------------------------------------------------------------------
# 1. Terraform を初期化:
#    cd app/infra/modules/cognito/examples/dev
#    terraform init
#
# 2. 実行計画を確認:
#    terraform plan
#
# 3. リソースを作成:
#    terraform apply
#
# 4. User Pool ID を確認:
#    terraform output user_pool_id
#
# 5. テストユーザーを作成（AWS CLI）:
#    aws cognito-idp admin-create-user \
#      --user-pool-id <USER_POOL_ID> \
#      --username test@example.com \
#      --user-attributes Name=email,Value=test@example.com Name=email_verified,Value=true \
#      --message-action SUPPRESS
#
# 6. ユーザーをグループに追加:
#    aws cognito-idp admin-add-user-to-group \
#      --user-pool-id <USER_POOL_ID> \
#      --username test@example.com \
#      --group-name admin
#
# 7. パスワードを設定:
#    aws cognito-idp admin-set-user-password \
#      --user-pool-id <USER_POOL_ID> \
#      --username test@example.com \
#      --password 'TempPassword123!' \
#      --permanent
