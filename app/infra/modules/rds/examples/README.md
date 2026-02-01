# RDS Module - 使用例

このディレクトリには、RDS モジュールの環境別使用例が含まれています。

## ディレクトリ構成

```
examples/
├── README.md     # このファイル
├── dev/          # 開発環境向け設定例
│   └── main.tf
└── prod/         # 本番環境向け設定例
    └── main.tf
```

## 開発環境（dev）

[dev/main.tf](./dev/main.tf)

### 特徴

- **コスト最適化**: 最小インスタンス（db.t3.micro）、シングル AZ 構成
- **開発効率**: 削除保護なし、最終スナップショット不要
- **デバッグ**: すべての SQL 文をログ出力
- **バックアップ**: 1日間のみ保持

### 推奨用途

- ローカル開発環境
- CI/CD テスト環境
- 機能検証環境

### 月額コスト目安

- RDS (db.t3.micro): 約 $15-20/月
- ストレージ (20GB): 約 $2-3/月
- バックアップ (1日): ほぼ無料

**合計: 約 $20-25/月**

## 本番環境（prod）

[prod/main.tf](./prod/main.tf)

### 特徴

- **高可用性**: より高性能なインスタンス（db.t3.small）、Multi-AZ 対応可能
- **信頼性**: 削除保護有効、30日間バックアップ保持
- **パフォーマンス**: Performance Insights 有効
- **セキュリティ**: DDL のみログ出力（パフォーマンス考慮）
- **スケーラビリティ**: 自動ストレージスケーリング（最大 500GB）

### 推奨用途

- 本番環境
- ステージング環境

### 月額コスト目安

**シングル AZ 構成の場合:**
- RDS (db.t3.small): 約 $30-40/月
- ストレージ (100GB): 約 $10-15/月
- バックアップ (30日): 約 $5-10/月
- Performance Insights: 無料（7日間保持の場合）

**合計: 約 $50-70/月**

**Multi-AZ 構成の場合:**
- RDS (db.t3.small Multi-AZ): 約 $70-80/月
- その他同様

**合計: 約 $90-110/月**

> **注意**: Multi-AZ はコストが約2倍になりますが、高可用性が必要な場合に推奨されます。

## 使い方

### 1. VPC モジュールの準備

まず VPC モジュールが作成されている必要があります。

```bash
cd ../../vpc
terraform init
terraform apply
```

### 2. 例のコピーと編集

使用したい環境の例をコピーします。

```bash
# 開発環境の場合
cp examples/dev/main.tf ../../environments/dev/rds.tf

# 本番環境の場合
cp examples/prod/main.tf ../../environments/prod/rds.tf
```

### 3. VPC との統合

コメントアウトされている VPC モジュールの参照を有効化します。

```hcl
# コメントを解除
module "vpc" {
  source = "../../vpc"
  # ...
}

module "rds" {
  source = "../.."

  # VPC の出力値を使用
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # ...
}
```

### 4. Lambda/CodeBuild との統合

Lambda や CodeBuild モジュールが作成されたら、セキュリティグループの設定を有効化します。

```hcl
module "rds" {
  # ...

  # コメントを解除
  lambda_security_group_id    = module.lambda.security_group_id
  codebuild_security_group_id = module.codebuild.security_group_id
}
```

### 5. デプロイ

```bash
cd ../../environments/dev  # または prod

terraform init
terraform plan
terraform apply
```

## 環境別の主な違い

| 設定項目 | dev | prod |
|---------|-----|------|
| インスタンスクラス | db.t3.micro | db.t3.small |
| ストレージ | 20GB | 100GB（最大500GB） |
| Multi-AZ | false | false（必要に応じてtrue） |
| 削除保護 | false | true |
| 最終スナップショット | スキップ | 作成 |
| バックアップ保持 | 1日 | 30日 |
| ログレベル | all | ddl |
| Performance Insights | 無効 | 有効 |
| 月額コスト | $20-25 | $50-110 |

## よくある質問

### Q: dev 環境で削除できない

A: `deletion_protection = true` になっている可能性があります。以下の手順で削除できます。

```hcl
# 1. 削除保護を無効化
deletion_protection = false
```

```bash
# 2. 適用
terraform apply

# 3. 削除
terraform destroy
```

### Q: 接続情報はどこにありますか？

A: AWS Secrets Manager に保存されています。

```bash
# AWS CLI で確認
aws secretsmanager get-secret-value \
  --secret-id zousho/dev/rds/credentials \
  --query SecretString \
  --output text | jq .
```

### Q: Multi-AZ は有効にすべきですか？

A: 本番環境で高可用性が必要な場合は有効化を推奨しますが、コストが約2倍になります。小規模システムやステージング環境では無効でも問題ありません。

### Q: Performance Insights は必要ですか？

A: 本番環境では有効化を推奨します。クエリのパフォーマンス分析に役立ちます。7日間保持であれば追加コストはかかりません。

### Q: バックアップから復元するには？

A: AWS CLI または AWS マネジメントコンソールから復元できます。

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier zousho-dev-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

## 参考資料

- [モジュールドキュメント](../README.md)
- [Amazon RDS 料金](https://aws.amazon.com/jp/rds/postgresql/pricing/)
- [RDS ベストプラクティス](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
