# Cognito Module

Amazon Cognito User Poolを構築するTerraformモジュール。

## 概要

このモジュールは、以下のリソースを作成します：

- **Cognito User Pool**: ユーザー認証基盤
- **Cognito User Pool Client**: アプリケーションクライアント
- **Cognito User Pool Domain**: （オプション）認証UIのドメイン
- **Cognito User Groups**: ユーザーグループ（管理者、一般ユーザーなど）

## 主な機能

- ✅ 柔軟なパスワードポリシー設定
- ✅ MFA（多要素認証）サポート
- ✅ OAuth 2.0 / OpenID Connect対応
- ✅ カスタム属性スキーマ定義
- ✅ ユーザーグループ管理
- ✅ セキュリティベストプラクティス適用

## 使用方法

### 基本的な構成

```hcl
module "cognito" {
  source = "../../modules/cognito"

  user_pool_name  = "zousho-dev-user-pool"
  app_client_name = "zousho-dev-app-client"

  # パスワードポリシー
  password_policy = {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # 管理者グループ
  user_groups = [
    {
      name        = "admin"
      description = "管理者グループ"
      precedence  = 1
    },
    {
      name        = "user"
      description = "一般ユーザーグループ"
      precedence  = 10
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "zousho"
  }
}
```

### OAuth設定を含む構成

```hcl
module "cognito" {
  source = "../../modules/cognito"

  user_pool_name  = "zousho-prod-user-pool"
  app_client_name = "zousho-prod-app-client"

  # OAuth設定
  oauth_flows         = ["code"]
  oauth_flows_enabled = true
  oauth_scopes        = ["openid", "email", "profile"]
  callback_urls       = ["https://example.com/callback"]
  logout_urls         = ["https://example.com/logout"]

  # ドメイン設定
  domain = "zousho-prod-auth"

  tags = {
    Environment = "prod"
    Project     = "zousho"
  }
}
```

### カスタム属性を含む構成

```hcl
module "cognito" {
  source = "../../modules/cognito"

  user_pool_name  = "zousho-dev-user-pool"
  app_client_name = "zousho-dev-app-client"

  # カスタム属性スキーマ
  schemas = [
    {
      name                = "department"
      attribute_data_type = "String"
      mutable             = true
      required            = false
      min_length          = 1
      max_length          = 100
    },
    {
      name                = "employee_id"
      attribute_data_type = "String"
      mutable             = false
      required            = true
      min_length          = 4
      max_length          = 10
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "zousho"
  }
}
```

## 入力変数

### 必須変数

| 変数名 | 説明 | 型 |
|--------|------|-----|
| `user_pool_name` | Cognito User Poolの名前 | `string` |
| `app_client_name` | App Clientの名前 | `string` |

### オプション変数

#### User Pool設定

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `username_attributes` | ユーザー名として使用する属性 | `list(string)` | `["email"]` |
| `username_case_sensitive` | ユーザー名の大文字小文字を区別するか | `bool` | `false` |
| `auto_verified_attributes` | 自動検証する属性 | `list(string)` | `["email"]` |
| `mfa_configuration` | MFA設定（OFF, OPTIONAL, ON） | `string` | `"OPTIONAL"` |

#### パスワードポリシー

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `password_policy` | パスワードポリシーの設定 | `object` | 下記参照 |

デフォルトのパスワードポリシー:
```hcl
{
  minimum_length                   = 8
  require_lowercase                = true
  require_uppercase                = true
  require_numbers                  = true
  require_symbols                  = true
  temporary_password_validity_days = 7
}
```

#### App Client設定

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `oauth_flows` | 許可するOAuthフロー | `list(string)` | `["code"]` |
| `oauth_flows_enabled` | OAuthフローを有効にするか | `bool` | `true` |
| `oauth_scopes` | 許可するOAuthスコープ | `list(string)` | `["openid", "email", "profile"]` |
| `callback_urls` | コールバックURL | `list(string)` | `[]` |
| `logout_urls` | ログアウトURL | `list(string)` | `[]` |
| `generate_client_secret` | クライアントシークレットを生成するか | `bool` | `false` |

#### トークン有効期限

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `token_validity` | トークンの有効期限 | `object` | 下記参照 |

デフォルトのトークン有効期限:
```hcl
{
  refresh_token_validity = 30     # 30日
  access_token_validity  = 60     # 60分
  id_token_validity      = 60     # 60分
}
```

#### ユーザーグループ

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `user_groups` | 作成するユーザーグループのリスト | `list(object)` | `[]` |

ユーザーグループの構造:
```hcl
[
  {
    name        = "admin"           # 必須: グループ名
    description = "管理者グループ"    # オプション: 説明
    precedence  = 1                 # オプション: 優先度（小さいほど高い）
    role_arn    = "arn:aws:..."     # オプション: IAMロールARN
  }
]
```

#### その他

| 変数名 | 説明 | 型 | デフォルト |
|--------|------|-----|-----------|
| `domain` | Cognito User Pool Domain（空文字の場合は作成しない） | `string` | `""` |
| `schemas` | カスタム属性スキーマ | `list(object)` | `[]` |
| `tags` | リソースに付与するタグ | `map(string)` | `{}` |

## 出力変数

| 変数名 | 説明 |
|--------|------|
| `user_pool_id` | Cognito User Pool ID |
| `user_pool_arn` | Cognito User Pool ARN |
| `user_pool_name` | Cognito User Pool Name |
| `user_pool_endpoint` | Cognito User Pool Endpoint |
| `app_client_id` | Cognito User Pool App Client ID |
| `app_client_secret` | Cognito User Pool App Client Secret（sensitive） |
| `domain` | Cognito User Pool Domain |
| `user_groups` | Cognito User Groups |

## セキュリティ考慮事項

### パスワードポリシー

本番環境では強力なパスワードポリシーを設定してください：

```hcl
password_policy = {
  minimum_length                   = 12  # 最低12文字
  require_lowercase                = true
  require_uppercase                = true
  require_numbers                  = true
  require_symbols                  = true
  temporary_password_validity_days = 7
}
```

### MFA（多要素認証）

本番環境ではMFAを必須または推奨に設定してください：

```hcl
mfa_configuration = "ON"  # または "OPTIONAL"
```

### トークン有効期限

セキュリティ要件に応じてトークンの有効期限を調整してください：

```hcl
token_validity = {
  refresh_token_validity = 7      # 7日（短めに設定）
  access_token_validity  = 15     # 15分（短めに設定）
  id_token_validity      = 15     # 15分（短めに設定）
}
```

### ユーザー列挙攻撃の防止

デフォルトで有効化されていますが、明示的に設定することを推奨：

```hcl
prevent_user_existence_errors = "ENABLED"
```

### クライアントシークレット

サーバーサイドアプリケーションの場合はクライアントシークレットを使用：

```hcl
generate_client_secret = true
```

## ベストプラクティス

### 1. 環境ごとの分離

dev/prod環境でUser Poolを分離してください：

```hcl
# dev環境
user_pool_name = "zousho-dev-user-pool"

# prod環境
user_pool_name = "zousho-prod-user-pool"
```

### 2. ユーザーグループの活用

権限管理にはユーザーグループを活用してください：

```hcl
user_groups = [
  {
    name        = "admin"
    description = "管理者：すべての操作が可能"
    precedence  = 1
  },
  {
    name        = "editor"
    description = "編集者：書籍の追加・編集が可能"
    precedence  = 5
  },
  {
    name        = "viewer"
    description = "閲覧者：閲覧のみ可能"
    precedence  = 10
  }
]
```

### 3. タグの活用

リソースの管理にタグを活用してください：

```hcl
tags = {
  Environment = "prod"
  Project     = "zousho"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
}
```

### 4. ライフサイクル管理

User Poolは誤削除を防ぐため `prevent_destroy` を設定しています。削除が必要な場合は、設定を明示的に変更してください。

## トラブルシューティング

### User Poolが作成できない

- リージョンの設定を確認してください
- IAM権限を確認してください（`cognito-idp:*` 権限が必要）

### ドメインが作成できない

- ドメイン名は小文字英数字とハイフンのみ使用可能です
- ドメイン名は一意である必要があります（リージョン内）

### カスタム属性が追加できない

- User Pool作成後、カスタム属性の削除はできません
- 属性の追加のみ可能です

## 参考資料

- [AWS Cognito User Pools 公式ドキュメント](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [Terraform AWS Provider - Cognito User Pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool)
- [OAuth 2.0](https://oauth.net/2/)
- [OpenID Connect](https://openid.net/connect/)
