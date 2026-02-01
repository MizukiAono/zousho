#######################################################
# User Pool Configuration
#######################################################

variable "user_pool_name" {
  description = "Cognito User Poolの名前"
  type        = string
}

variable "username_attributes" {
  description = "ユーザー名として使用する属性（email, phone_number, または両方）"
  type        = list(string)
  default     = ["email"]

  validation {
    condition = alltrue([
      for attr in var.username_attributes : contains(["email", "phone_number"], attr)
    ])
    error_message = "username_attributesには'email'または'phone_number'のみを指定できます。"
  }
}

variable "username_case_sensitive" {
  description = "ユーザー名の大文字小文字を区別するか"
  type        = bool
  default     = false
}

variable "auto_verified_attributes" {
  description = "自動検証する属性（email, phone_number）"
  type        = list(string)
  default     = ["email"]

  validation {
    condition = alltrue([
      for attr in var.auto_verified_attributes : contains(["email", "phone_number"], attr)
    ])
    error_message = "auto_verified_attributesには'email'または'phone_number'のみを指定できます。"
  }
}

variable "mfa_configuration" {
  description = "MFA設定（OFF, OPTIONAL, ON）"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "OPTIONAL", "ON"], var.mfa_configuration)
    error_message = "mfa_configurationは'OFF', 'OPTIONAL', 'ON'のいずれかである必要があります。"
  }
}

#######################################################
# Password Policy
#######################################################

variable "password_policy" {
  description = "パスワードポリシーの設定"
  type = object({
    minimum_length                   = number
    require_lowercase                = bool
    require_uppercase                = bool
    require_numbers                  = bool
    require_symbols                  = bool
    temporary_password_validity_days = number
  })
  default = {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  validation {
    condition     = var.password_policy.minimum_length >= 6 && var.password_policy.minimum_length <= 99
    error_message = "minimum_lengthは6以上99以下である必要があります。"
  }

  validation {
    condition     = var.password_policy.temporary_password_validity_days >= 0 && var.password_policy.temporary_password_validity_days <= 365
    error_message = "temporary_password_validity_daysは0以上365以下である必要があります。"
  }
}

#######################################################
# Account Recovery
#######################################################

variable "account_recovery_mechanism" {
  description = "アカウント回復メカニズム"
  type = object({
    name     = string
    priority = number
  })
  default = {
    name     = "verified_email"
    priority = 1
  }

  validation {
    condition     = contains(["verified_email", "verified_phone_number", "admin_only"], var.account_recovery_mechanism.name)
    error_message = "nameは'verified_email', 'verified_phone_number', 'admin_only'のいずれかである必要があります。"
  }
}

#######################################################
# Email Configuration
#######################################################

variable "email_configuration" {
  description = "メール設定"
  type = object({
    email_sending_account = string
  })
  default = {
    email_sending_account = "COGNITO_DEFAULT"
  }

  validation {
    condition     = contains(["COGNITO_DEFAULT", "DEVELOPER"], var.email_configuration.email_sending_account)
    error_message = "email_sending_accountは'COGNITO_DEFAULT'または'DEVELOPER'である必要があります。"
  }
}

#######################################################
# Device Configuration
#######################################################

variable "device_configuration" {
  description = "デバイス記憶設定"
  type = object({
    challenge_required_on_new_device      = bool
    device_only_remembered_on_user_prompt = bool
  })
  default = {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = true
  }
}

#######################################################
# Schema
#######################################################

variable "schemas" {
  description = "ユーザー属性のスキーマ定義"
  type = list(object({
    name                     = string
    attribute_data_type      = string
    developer_only_attribute = optional(bool, false)
    mutable                  = optional(bool, true)
    required                 = optional(bool, false)
    min_length               = optional(number, 0)
    max_length               = optional(number, 2048)
    min_value                = optional(number)
    max_value                = optional(number)
  }))
  default = []
}

#######################################################
# App Client Configuration
#######################################################

variable "app_client_name" {
  description = "App Clientの名前"
  type        = string
}

variable "oauth_flows" {
  description = "許可するOAuthフロー（code, implicit, client_credentials）"
  type        = list(string)
  default     = ["code"]

  validation {
    condition = alltrue([
      for flow in var.oauth_flows : contains(["code", "implicit", "client_credentials"], flow)
    ])
    error_message = "oauth_flowsには'code', 'implicit', 'client_credentials'のみを指定できます。"
  }
}

variable "oauth_flows_enabled" {
  description = "OAuthフローを有効にするか"
  type        = bool
  default     = true
}

variable "oauth_scopes" {
  description = "許可するOAuthスコープ"
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "callback_urls" {
  description = "コールバックURL"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "ログアウトURL"
  type        = list(string)
  default     = []
}

variable "explicit_auth_flows" {
  description = "サポートする認証フロー"
  type        = list(string)
  default = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

variable "token_validity" {
  description = "トークンの有効期限"
  type = object({
    refresh_token_validity = number
    access_token_validity  = number
    id_token_validity      = number
  })
  default = {
    refresh_token_validity = 30
    access_token_validity  = 60
    id_token_validity      = 60
  }
}

variable "token_validity_units" {
  description = "トークン有効期限の単位"
  type = object({
    refresh_token = string
    access_token  = string
    id_token      = string
  })
  default = {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  validation {
    condition = alltrue([
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.refresh_token),
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.access_token),
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.id_token)
    ])
    error_message = "token_validity_unitsには'seconds', 'minutes', 'hours', 'days'のいずれかを指定できます。"
  }
}

variable "generate_client_secret" {
  description = "クライアントシークレットを生成するか"
  type        = bool
  default     = false
}

variable "enable_token_revocation" {
  description = "トークン取り消しを有効にするか"
  type        = bool
  default     = true
}

variable "prevent_user_existence_errors" {
  description = "ユーザー存在エラーを防ぐ設定（ENABLED, LEGACY）"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "LEGACY"], var.prevent_user_existence_errors)
    error_message = "prevent_user_existence_errorsは'ENABLED'または'LEGACY'である必要があります。"
  }
}

variable "enable_propagate_additional_user_context_data" {
  description = "追加のユーザーコンテキストデータを伝播するか"
  type        = bool
  default     = false
}

variable "read_attributes" {
  description = "読み取り可能な属性"
  type        = list(string)
  default     = []
}

variable "write_attributes" {
  description = "書き込み可能な属性"
  type        = list(string)
  default     = []
}

variable "supported_identity_providers" {
  description = "サポートする認証プロバイダー"
  type        = list(string)
  default     = ["COGNITO"]
}

#######################################################
# User Pool Domain (Optional)
#######################################################

variable "domain" {
  description = "Cognito User Pool Domain（空文字の場合は作成しない）"
  type        = string
  default     = ""
}

#######################################################
# User Groups
#######################################################

variable "user_groups" {
  description = "作成するユーザーグループのリスト"
  type = list(object({
    name        = string
    description = optional(string)
    precedence  = optional(number)
    role_arn    = optional(string)
  }))
  default = []
}

#######################################################
# Tags
#######################################################

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
