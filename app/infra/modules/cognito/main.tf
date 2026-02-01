#######################################################
# Cognito User Pool
#######################################################

resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  # パスワードポリシー
  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_uppercase                = var.password_policy.require_uppercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  # ユーザー名属性
  username_attributes = var.username_attributes

  # ユーザー名の大文字小文字を区別しない
  username_configuration {
    case_sensitive = var.username_case_sensitive
  }

  # 自動検証する属性
  auto_verified_attributes = var.auto_verified_attributes

  # MFA設定
  mfa_configuration = var.mfa_configuration

  # アカウント回復設定
  account_recovery_setting {
    recovery_mechanism {
      name     = var.account_recovery_mechanism.name
      priority = var.account_recovery_mechanism.priority
    }
  }

  # メール設定
  email_configuration {
    email_sending_account = var.email_configuration.email_sending_account
  }

  # デバイス記憶設定
  device_configuration {
    challenge_required_on_new_device      = var.device_configuration.challenge_required_on_new_device
    device_only_remembered_on_user_prompt = var.device_configuration.device_only_remembered_on_user_prompt
  }

  # ユーザー属性のスキーマ
  dynamic "schema" {
    for_each = var.schemas
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = lookup(schema.value, "developer_only_attribute", false)
      mutable                  = lookup(schema.value, "mutable", true)
      required                 = lookup(schema.value, "required", false)

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [1] : []
        content {
          min_length = lookup(schema.value, "min_length", 0)
          max_length = lookup(schema.value, "max_length", 2048)
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "Number" ? [1] : []
        content {
          min_value = lookup(schema.value, "min_value", null)
          max_value = lookup(schema.value, "max_value", null)
        }
      }
    }
  }

  # タグ
  tags = merge(
    var.tags,
    {
      Name = var.user_pool_name
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

#######################################################
# Cognito User Pool Client
#######################################################

resource "aws_cognito_user_pool_client" "main" {
  name         = var.app_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth設定
  allowed_oauth_flows                  = var.oauth_flows
  allowed_oauth_flows_user_pool_client = var.oauth_flows_enabled
  allowed_oauth_scopes                 = var.oauth_scopes
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  # サポートする認証フロー
  explicit_auth_flows = var.explicit_auth_flows

  # トークンの有効期限
  refresh_token_validity = var.token_validity.refresh_token_validity
  access_token_validity  = var.token_validity.access_token_validity
  id_token_validity      = var.token_validity.id_token_validity

  token_validity_units {
    refresh_token = var.token_validity_units.refresh_token
    access_token  = var.token_validity_units.access_token
    id_token      = var.token_validity_units.id_token
  }

  # セキュリティ設定
  generate_secret                               = var.generate_client_secret
  enable_token_revocation                       = var.enable_token_revocation
  prevent_user_existence_errors                 = var.prevent_user_existence_errors
  enable_propagate_additional_user_context_data = var.enable_propagate_additional_user_context_data

  # 読み書き可能な属性
  read_attributes  = var.read_attributes
  write_attributes = var.write_attributes

  # サポートする認証プロバイダー
  supported_identity_providers = var.supported_identity_providers
}

#######################################################
# Cognito User Pool Domain (Optional)
#######################################################

resource "aws_cognito_user_pool_domain" "main" {
  count = var.domain != "" ? 1 : 0

  domain       = var.domain
  user_pool_id = aws_cognito_user_pool.main.id
}

#######################################################
# Cognito User Groups
#######################################################

resource "aws_cognito_user_group" "groups" {
  for_each = { for group in var.user_groups : group.name => group }

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.main.id
  description  = lookup(each.value, "description", null)
  precedence   = lookup(each.value, "precedence", null)
  role_arn     = lookup(each.value, "role_arn", null)
}
