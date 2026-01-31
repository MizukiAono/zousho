---
description: デプロイ前チェックと手順ガイド。dev/prod環境へのデプロイ確認。
user_invocable: true
---

# デプロイスキル

dev/prod 環境へのデプロイ前チェックと手順ガイドです。

## デプロイフロー概要

```
develop ブランチ → dev 環境（自動デプロイ）
main ブランチ    → prod 環境（手動承認後デプロイ）
```

## デプロイ前チェックリスト

### 共通チェック

- [ ] 全テストがパスしている
- [ ] カバレッジが 80% 以上
- [ ] Lint エラーがない
- [ ] Terraform fmt 差分がない
- [ ] レビュー承認が 1 名以上ある

### dev 環境デプロイ前

```bash
# Backend テスト
cd app/backend
pytest --cov
ruff check .
black --check .

# Frontend テスト
cd app/frontend/user
npm run test -- --coverage
npm run lint

cd app/frontend/admin
npm run test -- --coverage
npm run lint

# Terraform 検証
cd app/infra/environments/dev
terraform init
terraform validate
terraform fmt -check -recursive
terraform plan
```

### prod 環境デプロイ前（追加チェック）

- [ ] dev 環境で動作確認済み
- [ ] データベースマイグレーションの影響を確認
- [ ] ロールバック手順を確認
- [ ] RDS スナップショットを取得

```bash
# prod 環境の Terraform plan を確認
cd app/infra/environments/prod
terraform init
terraform plan

# RDS スナップショット作成（手動）
aws rds create-db-snapshot \
    --db-instance-identifier zousho-db-prod \
    --db-snapshot-identifier zousho-db-prod-$(date +%Y%m%d-%H%M%S)
```

## デプロイ手順

### dev 環境へのデプロイ

develop ブランチへのマージで自動デプロイされます。

1. feature ブランチから develop へ PR を作成
2. CI がパスすることを確認
3. レビュー承認を受ける
4. マージ → 自動デプロイ開始

```bash
# ローカルで確認
git checkout develop
git pull origin develop
git log --oneline -5  # 最新コミットを確認
```

### prod 環境へのデプロイ

1. develop から main へ PR を作成
2. CI がパスすることを確認
3. レビュー承認を受ける
4. マージ
5. **手動承認** が必要（GitHub Actions の Environment protection rules）
6. 承認後、自動デプロイ開始

```bash
# デプロイ後の確認
curl -I https://api.example.com/health
curl -I https://app.example.com
```

## デプロイ順序

```
1. Terraform Apply（インフラ更新）
   ├── Lambda 関数更新
   ├── API Gateway 更新
   └── その他リソース
2. S3 アップロード（フロントエンド）
   ├── user フロントエンド
   └── admin フロントエンド
3. CloudFront キャッシュ無効化
```

## ロールバック手順

### Frontend ロールバック（5-10分）

```bash
# 前バージョンの S3 オブジェクトを復元
aws s3 sync s3://backup-bucket/previous-version s3://frontend-bucket --delete

# CloudFront キャッシュ無効化
aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"
```

### Lambda ロールバック（1-2分）

```bash
# 前バージョンのエイリアス切り替え
aws lambda update-alias \
    --function-name zousho-api \
    --name live \
    --function-version $PREVIOUS_VERSION
```

### Infrastructure ロールバック（10-30分）

```bash
# 前の Terraform state に戻す
cd app/infra/environments/prod
git checkout HEAD~1 -- .
terraform init
terraform apply
```

### Database ロールバック

**注意**: データベースのロールバックは複雑です。

1. マイグレーションの DOWN スクリプトを実行
2. または、RDS スナップショットから復元

```bash
# スナップショットからリストア（最終手段）
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier zousho-db-restored \
    --db-snapshot-identifier zousho-db-prod-YYYYMMDD-HHMMSS
```

## 監視項目

デプロイ後に以下を監視：

| 項目 | 閾値 | 対応 |
|------|------|------|
| Lambda Errors | > 0 | ログ確認 → ロールバック検討 |
| Lambda Duration | > 3秒 | パフォーマンス調査 |
| API Gateway 5XX | > 1% | 原因調査 → ロールバック検討 |
| API Gateway Latency | > 1秒 | パフォーマンス調査 |
| RDS CPU | > 80% | スケールアップ検討 |

```bash
# CloudWatch でエラーを確認
aws logs filter-log-events \
    --log-group-name /aws/lambda/zousho-api \
    --start-time $(date -d '10 minutes ago' +%s000) \
    --filter-pattern "ERROR"
```

## トラブルシューティング

### CI が失敗する

```bash
# ローカルでテストを実行
cd app/backend && pytest -v
cd app/frontend/user && npm run test
cd app/frontend/admin && npm run test

# Lint を確認
cd app/backend && ruff check . && black --check .
cd app/frontend/user && npm run lint
```

### Terraform Apply が失敗する

```bash
# state を確認
terraform state list
terraform show

# 特定リソースの状態を確認
terraform state show aws_lambda_function.api

# 手動で state を修正（最終手段）
terraform state rm aws_lambda_function.api
```

### デプロイ後にエラーが発生

1. CloudWatch Logs でエラー内容を確認
2. 影響範囲を評価
3. 必要に応じてロールバック
4. 原因を調査して修正

```bash
# 最新のログを確認
aws logs tail /aws/lambda/zousho-api --follow
```

## シークレット管理

| 環境 | 管理場所 | ローテーション |
|------|----------|----------------|
| ローカル | .env ファイル | - |
| dev | AWS Secrets Manager | 90日 |
| prod | AWS Secrets Manager | 90日 |

```bash
# シークレットを確認（本番作業時は注意）
aws secretsmanager get-secret-value \
    --secret-id zousho/dev/database \
    --query SecretString
```

## チェックリスト（最終確認）

### dev デプロイ

- [ ] 全テストパス
- [ ] カバレッジ 80% 以上
- [ ] Lint エラーなし
- [ ] `terraform plan` の差分を確認
- [ ] PR レビュー承認済み

### prod デプロイ

- [ ] dev 環境で動作確認済み
- [ ] 全テストパス
- [ ] カバレッジ 80% 以上
- [ ] Lint エラーなし
- [ ] `terraform plan` の差分を確認
- [ ] RDS スナップショット取得済み
- [ ] PR レビュー承認済み
- [ ] ロールバック手順を理解している
- [ ] 監視体制を確認

## 緊急連絡先

| 役割 | 連絡先 |
|------|--------|
| インフラ担当 | @infra-team |
| バックエンド担当 | @backend-team |
| フロントエンド担当 | @frontend-team |
