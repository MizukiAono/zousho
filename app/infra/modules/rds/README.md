# RDS PostgreSQL Module

Amazon RDS for PostgreSQL を構築するための Terraform モジュールです。

## 機能

- RDS PostgreSQL インスタンスの作成
- プライベートサブネットへの配置
- セキュリティグループの自動構成
- Secrets Manager による認証情報管理
- 自動バックアップとスナップショット
- CloudWatch Logs 統合
- 日本語対応（UTF8、Asia/Tokyo）

## 必須変数

| 変数名 | 型 | 説明 |
|--------|-----|------|
| `project` | string | プロジェクト名 |
| `environment` | string | 環境名（`dev` または `prod`） |
| `vpc_id` | string | VPC ID |
| `private_subnet_ids` | list(string) | RDS を配置するプライベートサブネット ID のリスト |

## オプション変数（主要なもの）

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `db_name` | `"zousho"` | データベース名 |
| `db_username` | `"postgres"` | マスターユーザー名 |
| `instance_class` | `"db.t3.micro"` | RDS インスタンスクラス |
| `allocated_storage` | `20` | 初期ストレージ容量（GB） |
| `multi_az` | `false` | Multi-AZ 構成の有効化 |
| `deletion_protection` | `true` | 削除保護の有効化 |
| `skip_final_snapshot` | `false` | 削除時の最終スナップショットスキップ |
| `lambda_security_group_id` | `""` | Lambda セキュリティグループ ID（接続許可用） |
| `codebuild_security_group_id` | `""` | CodeBuild セキュリティグループ ID（接続許可用） |

完全な変数リストは [variables.tf](./variables.tf) を参照してください。

## 出力値

| 出力名 | 説明 |
|--------|------|
| `db_instance_id` | RDS インスタンス ID |
| `db_instance_endpoint` | RDS エンドポイント（ホスト名:ポート） |
| `db_instance_address` | RDS ホスト名 |
| `db_instance_port` | RDS ポート番号 |
| `rds_security_group_id` | RDS セキュリティグループ ID |
| `secret_arn` | Secrets Manager シークレット ARN |
| `secret_name` | Secrets Manager シークレット名 |

## 使用例

### 基本的な使用方法

```hcl
module "rds" {
  source = "../../modules/rds"

  project     = "zousho"
  environment = "dev"

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
}
```

### dev 環境（推奨設定）

```hcl
module "rds" {
  source = "../../modules/rds"

  project     = "zousho"
  environment = "dev"

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  # dev 環境向け設定
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  multi_az             = false
  deletion_protection  = false  # terraform destroy を許可
  skip_final_snapshot  = true   # 削除時にスナップショット不要

  # 詳細なログ出力
  log_statement = "all"

  # Lambda からの接続許可（モジュール作成後）
  # lambda_security_group_id = module.lambda.security_group_id
}
```

### prod 環境（推奨設定）

```hcl
module "rds" {
  source = "../../modules/rds"

  project     = "zousho"
  environment = "prod"

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  # prod 環境向け設定
  instance_class       = "db.t3.small"      # より高性能なインスタンス
  allocated_storage    = 100
  max_allocated_storage = 500               # 自動スケーリング上限
  multi_az             = true                # 高可用性構成（予算に応じて）
  deletion_protection  = true                # 誤削除防止
  skip_final_snapshot  = false               # 削除時にスナップショット作成

  backup_retention_period = 30              # 30日間バックアップ保持

  # DDL のみログ出力（パフォーマンス考慮）
  log_statement = "ddl"

  # Performance Insights 有効化
  performance_insights_enabled = true

  # Lambda からの接続許可
  lambda_security_group_id = module.lambda.security_group_id

  # CodeBuild（DBマイグレーション）からの接続許可
  codebuild_security_group_id = module.codebuild.security_group_id
}
```

詳細な例は [examples/](./examples/) ディレクトリを参照してください。

## セキュリティ

### ネットワークセキュリティ

- RDS は**プライベートサブネット**に配置されます
- パブリックアクセスは**無効化**されます
- Lambda/CodeBuild からのアクセスのみセキュリティグループで許可されます

### データ暗号化

- ストレージ暗号化が有効化されます（AWS 管理キー使用）
- 必要に応じてカスタマーマネージドキー（KMS）への変更も可能です

### 認証情報管理

- マスターパスワードは 32 文字のランダム文字列で自動生成されます
- 認証情報は AWS Secrets Manager に保存されます
- Secrets Manager のシークレット名: `{project}/{environment}/rds/credentials`

### 接続情報の取得

Lambda 関数などから接続情報を取得する例：

```python
import boto3
import json

def get_db_credentials(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# 使用例
credentials = get_db_credentials('zousho/prod/rds/credentials')
connection_string = credentials['connection_string']
# postgresql://postgres:xxxxx@host:5432/zousho
```

## バックアップとリカバリ

### 自動バックアップ

- デフォルトで 7 日間の自動バックアップが有効
- バックアップウィンドウ: 18:00-19:00 UTC（JST 03:00-04:00）
- メンテナンスウィンドウ: 日曜 19:00-20:00 UTC（JST 日曜 04:00-05:00）

### 最終スナップショット

- `skip_final_snapshot = false` の場合、削除時に最終スナップショットを作成
- スナップショット名: `{project}-{environment}-db-final-snapshot-{timestamp}`
- **prod 環境では必ず `false` を設定してください**

## モニタリング

### CloudWatch Logs

以下のログが CloudWatch Logs にエクスポートされます：

- PostgreSQL ログ
- アップグレードログ

### Performance Insights

- `performance_insights_enabled = true` で有効化
- クエリパフォーマンスの詳細分析が可能
- **prod 環境での有効化を推奨**

### 拡張モニタリング

現在は未サポートですが、必要に応じて追加可能です。

## トラブルシューティング

### Lambda から RDS に接続できない

1. Lambda が VPC 内に配置されているか確認
2. `lambda_security_group_id` が正しく設定されているか確認
3. RDS と Lambda が同じ VPC 内にあるか確認

### terraform destroy が失敗する

`deletion_protection = true` の場合、削除保護が有効です：

```hcl
# 一時的に削除保護を無効化
deletion_protection = false
```

適用後、再度 `terraform destroy` を実行してください。

## 制限事項

- PostgreSQL のみサポート（MySQL などは未サポート）
- シングルリージョン構成（クロスリージョンレプリカは未サポート）
- Read Replica の自動構成は未サポート

## バージョン要件

- Terraform >= 1.0
- AWS Provider ~> 6.0
- Random Provider ~> 3.6

## ライセンス

このモジュールは蔵書管理システムの一部です。

## 参考資料

- [Amazon RDS for PostgreSQL ドキュメント](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/)
- [Terraform AWS Provider - RDS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [プロジェクトアーキテクチャ](../../../../docs/system-architecture.md)
