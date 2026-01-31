---
paths: app/infra/**
---

# インフラ設定ガイド

インフラ開発に関するガイドです。

## 技術スタック

| 用途 | 技術 |
|------|------|
| IaC | Terraform |
| Compute | AWS Lambda |
| API | API Gateway |
| Database | Amazon RDS for PostgreSQL |
| Auth | Amazon Cognito |
| Networking | VPC / Subnets |

## ディレクトリ構成

```
app/
└── infra/
    ├── modules/           # 再利用可能なモジュール
    │   ├── lambda/
    │   ├── api_gateway/
    │   ├── rds/
    │   ├── cognito/
    │   └── vpc/
    └── environments/      # 環境別設定
        ├── dev/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── terraform.tfvars
        └── prod/
            ├── main.tf
            ├── variables.tf
            └── terraform.tfvars
```

## 開発コマンド

```bash
cd infra/environments/dev
terraform init            # 初期化
terraform plan            # 差分確認
terraform apply           # 適用
terraform destroy         # 削除（注意）
terraform fmt -recursive  # フォーマット
terraform validate        # 構文検証
```

## コーディング規約

- `terraform fmt` でフォーマット
- リソース名: snake_case
- モジュールは再利用可能な単位で分割
- 環境ごとの差異は variables で吸収

## セキュリティ要件

- RDS はプライベートサブネットに配置し、Lambda からのみアクセス可能にすること
- Lambda は VPC 内に配置すること
- すべての API は Cognito Authorizer で保護すること
- 本番環境のシークレットは AWS Secrets Manager で管理すること

## 環境別設定

### dev 環境

- コスト最適化優先
- 小規模インスタンス使用

### prod 環境

- 可用性・信頼性優先
- シングル AZ 構成
- バックアップ設定必須

## 参照ドキュメント

- アーキテクチャ: @docs/system-architecture.md
