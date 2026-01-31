# CI/CD設計書

本ドキュメントでは、蔵書管理システムのCI/CD（継続的インテグレーション/継続的デリバリー）パイプラインを定義します。

## 1. 全体概要

```mermaid
flowchart TB
    subgraph Dev["開発フェーズ"]
        Developer["開発者"]
        LocalTest["ローカルテスト"]
        Push["Git Push"]
    end

    subgraph CI["CI: 継続的インテグレーション"]
        subgraph Tests["テスト（並列実行）"]
            BackendTest["Backend<br/>pytest"]
            FrontendUserTest["Frontend User<br/>Vitest"]
            FrontendAdminTest["Frontend Admin<br/>Vitest"]
            TerraformValidate["Terraform<br/>validate"]
            MigrationValidate["Migration<br/>SQL検証"]
        end
        subgraph Quality["品質チェック（並列実行）"]
            BackendLint["Backend<br/>ruff + black"]
            FrontendLint["Frontend<br/>ESLint + Prettier"]
            TerraformFmt["Terraform<br/>fmt"]
        end
        Coverage["カバレッジレポート"]
    end

    subgraph CD["CD: 継続的デリバリー"]
        Build["ビルド"]
        DeployDev["dev環境<br/>デプロイ"]
        CodeBuild["CodeBuild<br/>dbmate up"]
        DeployProd["prod環境<br/>デプロイ"]
    end

    Developer --> LocalTest
    LocalTest --> Push
    Push --> Tests
    Push --> Quality
    Tests --> Coverage
    Quality --> Coverage
    Coverage --> Build
    Build --> DeployDev
    DeployDev --> CodeBuild
    CodeBuild --> DeployProd
```

---

## 2. ブランチ戦略

```mermaid
gitGraph
    commit id: "initial"
    branch develop
    checkout develop
    commit id: "feat-1"
    branch feature/book-list
    checkout feature/book-list
    commit id: "implement"
    commit id: "test"
    checkout develop
    merge feature/book-list id: "merge-feat"
    checkout main
    merge develop id: "release-v1.0" tag: "v1.0.0"
```

### 2.1 ブランチ定義

| ブランチ | 用途 | 保護設定 | デプロイ先 |
|----------|------|----------|------------|
| `main` | 本番リリース | 必須 | prod環境 |
| `develop` | 開発統合 | 必須 | dev環境 |
| `feature/*` | 機能開発 | - | - |
| `hotfix/*` | 緊急修正 | - | prod環境 |

### 2.2 ブランチ保護ルール

```mermaid
flowchart LR
    subgraph Rules["main / develop ブランチ保護"]
        PR["PRが必須"]
        Review["レビュー承認が必須"]
        CI["CIパス必須"]
        NoForce["Force Push禁止"]
    end
```

| ルール | main | develop |
|--------|------|---------|
| PR必須 | Yes | Yes |
| レビュー承認数 | 1 | 1 |
| CIパス必須 | Yes | Yes |
| Force Push禁止 | Yes | Yes |
| 直接Push禁止 | Yes | Yes |

---

## 3. CIパイプライン詳細

### 3.1 トリガー条件

```mermaid
flowchart TB
    subgraph Triggers["トリガー"]
        PR["Pull Request"]
        PushDevelop["Push to develop"]
        PushMain["Push to main"]
    end

    subgraph Actions["実行アクション"]
        CIOnly["CI のみ"]
        CIDeployDev["CI + dev デプロイ"]
        CIDeployProd["CI + prod デプロイ"]
    end

    PR --> CIOnly
    PushDevelop --> CIDeployDev
    PushMain --> CIDeployProd
```

| イベント | トリガー | 実行内容 |
|----------|----------|----------|
| Pull Request | 作成・更新 | CI（テスト・Lint） |
| Push to develop | マージ | CI + dev環境デプロイ |
| Push to main | マージ | CI + prod環境デプロイ |

### 3.2 ジョブ構成

```mermaid
flowchart TB
    subgraph CI["CI ワークフロー"]
        subgraph Parallel1["並列実行グループ1"]
            Backend["backend-test"]
            FrontendUser["frontend-user-test"]
            FrontendAdmin["frontend-admin-test"]
            Terraform["terraform-validate"]
            MigrationCheck["migration-validate"]
        end

        subgraph Parallel2["並列実行グループ2"]
            BackendLint["backend-lint"]
            FrontendUserLint["frontend-user-lint"]
            FrontendAdminLint["frontend-admin-lint"]
            TerraformLint["terraform-fmt"]
        end

        Summary["結果サマリー"]
    end

    Parallel1 --> Summary
    Parallel2 --> Summary
```

---

## 4. テスト戦略

### 4.1 テストピラミッド

```mermaid
flowchart TB
    subgraph Pyramid["テストピラミッド"]
        E2E["E2Eテスト<br/>（将来実装）"]
        Integration["統合テスト"]
        Unit["ユニットテスト"]
    end

    E2E --> Integration
    Integration --> Unit
```

### 4.2 テスト要件

| レイヤー | フレームワーク | カバレッジ目標 | 必須ケース |
|----------|----------------|----------------|------------|
| Backend | pytest | 80%以上 | 正常系・異常系・境界値 |
| Frontend User | Vitest | 80%以上 | コンポーネント・フック |
| Frontend Admin | Vitest | 80%以上 | CRUD操作 |

### 4.3 テスト実行環境

```mermaid
flowchart LR
    subgraph BackendTest["Backend テスト環境"]
        Python["Python 3.12"]
        PostgresContainer["PostgreSQL<br/>（Docker）"]
    end

    subgraph FrontendTest["Frontend テスト環境"]
        Node["Node.js 20"]
        MSW["MSW<br/>（APIモック）"]
    end

    Python --> PostgresContainer
    Node --> MSW
```

---

## 5. CDパイプライン詳細

### 5.1 デプロイフロー

```mermaid
flowchart TB
    subgraph Build["ビルドステージ"]
        BuildFrontendUser["Frontend User<br/>npm run build"]
        BuildFrontendAdmin["Frontend Admin<br/>npm run build"]
        BuildLambda["Lambda<br/>パッケージング"]
    end

    subgraph Deploy["デプロイステージ (GitHub Actions)"]
        TerraformPlan["Terraform Plan"]
        TerraformApply["Terraform Apply"]
        TriggerCodeBuild["CodeBuild 起動"]
        S3Deploy["S3 アップロード"]
        CFInvalidate["CloudFront<br/>キャッシュ無効化"]
    end

    subgraph AWS["AWS VPC内"]
        CodeBuild["CodeBuild<br/>dbmate up"]
        RDS["RDS"]
    end

    BuildFrontendUser --> S3Deploy
    BuildFrontendAdmin --> S3Deploy
    BuildLambda --> TerraformApply
    TerraformPlan --> TerraformApply
    TerraformApply --> TriggerCodeBuild
    TriggerCodeBuild --> CodeBuild
    CodeBuild --> RDS
    CodeBuild --> S3Deploy
    S3Deploy --> CFInvalidate
```

### 5.2 環境別デプロイ

| 環境 | トリガー | 承認 | Terraform Workspace |
|------|----------|------|---------------------|
| dev | develop マージ | 自動 | dev |
| prod | main マージ | 手動承認 | prod |

### 5.3 デプロイ順序

```mermaid
sequenceDiagram
    autonumber
    participant GH as GitHub Actions
    participant TF as Terraform
    participant CB as CodeBuild (VPC内)
    participant RDS as PostgreSQL
    participant S3 as S3
    participant CF as CloudFront

    GH->>TF: terraform plan
    TF->>GH: Plan結果
    GH->>TF: terraform apply
    TF->>GH: Apply完了（Lambda更新含む）
    GH->>CB: CodeBuild 起動 (start-build)
    CB->>CB: dbmate バイナリ取得
    CB->>RDS: dbmate up 実行
    RDS->>CB: マイグレーション完了
    CB->>GH: ビルド完了
    GH->>S3: フロントエンドアップロード
    S3->>GH: アップロード完了
    GH->>CF: キャッシュ無効化
    CF->>GH: 無効化完了
```

---

## 6. GitHub Actions ワークフロー構成

### 6.1 ファイル構成

```
.github/
└── workflows/
    ├── ci.yml              # CI: テスト・Lint・マイグレーション検証
    ├── deploy-dev.yml      # CD: dev環境デプロイ（CodeBuildでマイグレーション）
    ├── deploy-prod.yml     # CD: prod環境デプロイ（CodeBuildでマイグレーション）
    └── terraform-plan.yml  # Terraform Plan（PR用）

app/backend/
├── migrations/             # dbmate形式マイグレーションファイル
│   ├── 20240101000000_create_books_table.sql
│   ├── 20240101000001_create_rentals_table.sql
│   └── YYYYMMDDHHMMSS_<description>.sql
└── buildspec.yml           # CodeBuild用ビルド仕様

app/infra/
└── modules/
    └── codebuild/          # CodeBuildモジュール（Terraform）
```

### 6.2 ワークフロー詳細

#### ci.yml

| ジョブ | 実行内容 | 条件 |
|--------|----------|------|
| backend-test | pytest --cov | 常時 |
| backend-lint | ruff check, black --check | 常時 |
| frontend-user-test | npm test -- --coverage | 常時 |
| frontend-user-lint | npm run lint | 常時 |
| frontend-admin-test | npm test -- --coverage | 常時 |
| frontend-admin-lint | npm run lint | 常時 |
| terraform-validate | terraform validate | infra変更時 |
| terraform-fmt | terraform fmt -check | infra変更時 |
| migration-validate | dbmate形式検証・SQL構文チェック | migrations変更時 |

#### deploy-dev.yml

| ステップ | 実行内容 |
|----------|----------|
| 1. Checkout | コード取得 |
| 2. Setup | 環境セットアップ（Python, Node.js, Terraform） |
| 3. Build Frontend | npm run build (user, admin) |
| 4. Package Lambda | zip パッケージ作成 |
| 5. Terraform Apply | dev環境にインフラ適用 |
| 6. DB Migration | CodeBuild起動 → dbmate up 実行 |
| 7. Deploy to S3 | フロントエンド静的ファイルアップロード |
| 8. Invalidate CloudFront | キャッシュ無効化 |

#### deploy-prod.yml

| ステップ | 実行内容 |
|----------|----------|
| 1. Approval | 手動承認待ち |
| 2-8 | deploy-dev.yml と同様（prod環境向け） |

---

## 7. シークレット管理

### 7.1 GitHub Secrets

| シークレット名 | 説明 | 使用ワークフロー |
|----------------|------|------------------|
| `AWS_ACCESS_KEY_ID` | AWSアクセスキーID | deploy-* |
| `AWS_SECRET_ACCESS_KEY` | AWSシークレットキー | deploy-* |
| `AWS_REGION` | AWSリージョン | deploy-* |

### 7.2 環境別変数

```mermaid
flowchart LR
    subgraph GitHub["GitHub"]
        Secrets["Secrets"]
        EnvDev["Environment: dev"]
        EnvProd["Environment: prod"]
    end

    subgraph AWS["AWS"]
        SecretsManager["Secrets Manager"]
    end

    Secrets --> EnvDev
    Secrets --> EnvProd
    EnvDev --> SecretsManager
    EnvProd --> SecretsManager
```

| 変数 | dev | prod |
|------|-----|------|
| `TF_WORKSPACE` | dev | prod |
| `CLOUDFRONT_DISTRIBUTION_ID` | 環境固有 | 環境固有 |
| `S3_BUCKET` | 環境固有 | 環境固有 |

---

## 8. 品質ゲート

### 8.1 マージ条件

```mermaid
flowchart TB
    subgraph Gates["品質ゲート"]
        AllTestsPass["全テストパス"]
        CoverageThreshold["カバレッジ<br/>80%以上"]
        LintPass["Lint パス"]
        ReviewApproved["レビュー承認"]
    end

    subgraph Result["結果"]
        CanMerge["マージ可能"]
        Blocked["マージ不可"]
    end

    AllTestsPass --> CanMerge
    CoverageThreshold --> CanMerge
    LintPass --> CanMerge
    ReviewApproved --> CanMerge
```

### 8.2 必須チェック項目

| チェック項目 | 基準 | ブロック対象 |
|--------------|------|--------------|
| テスト | 全パス | main, develop |
| カバレッジ | 80%以上 | main, develop |
| Lint | エラー0 | main, develop |
| Terraform fmt | 差分なし | main, develop |
| レビュー | 1名以上承認 | main, develop |

---

## 9. ロールバック戦略

### 9.1 ロールバック手順

```mermaid
flowchart TB
    subgraph Detection["検知"]
        Monitor["監視アラート"]
        Manual["手動検知"]
    end

    subgraph Decision["判断"]
        Assess["影響度評価"]
    end

    subgraph Action["対応"]
        RevertCommit["Git Revert"]
        TerraformRollback["Terraform<br/>前バージョン適用"]
        LambdaRollback["Lambda<br/>前バージョン"]
    end

    Monitor --> Assess
    Manual --> Assess
    Assess --> RevertCommit
    Assess --> TerraformRollback
    Assess --> LambdaRollback
```

### 9.2 各コンポーネントのロールバック

| コンポーネント | 方法 | 所要時間目安 |
|----------------|------|--------------|
| Frontend | S3 前バージョン復元 + CF無効化 | 5-10分 |
| Lambda | 前バージョンのエイリアス切り替え | 1-2分 |
| Infrastructure | Terraform 前状態適用 | 10-30分 |
| Database | 下記参照 | ケースによる |

### 9.3 DBマイグレーションのロールバック（dbmate）

dbmate は `-- migrate:down` セクションでロールバックをサポート。

```mermaid
flowchart TB
    subgraph Prevention["予防策"]
        BackwardCompat["後方互換性を保つ"]
        SmallChange["小さな変更に分割"]
        DryRun["本番適用前のDry Run"]
    end

    subgraph Recovery["復旧手段"]
        DbmateRollback["dbmate rollback"]
        NewMigration["修正マイグレーション作成"]
        Snapshot["RDSスナップショット復元"]
    end
```

| 状況 | 対応方法 |
|------|----------|
| 直前のマイグレーションを取り消し | `dbmate rollback` を実行 |
| カラム追加後に問題発覚 | `dbmate rollback` または新規マイグレーション |
| データ破損 | RDSスナップショットから復元 |
| 制約追加でエラー | `dbmate rollback` で制約を削除 |

**重要**: 各マイグレーションファイルには必ず `-- migrate:down` セクションを記載すること。

```sql
-- migrate:up
ALTER TABLE books ADD COLUMN publisher VARCHAR(255);

-- migrate:down
ALTER TABLE books DROP COLUMN publisher;
```

---

## 10. デプロイ通知

### 10.1 通知フロー

```mermaid
flowchart LR
    subgraph CI["CI/CD"]
        Success["成功"]
        Failure["失敗"]
    end

    subgraph Notification["通知先"]
        Slack["Slack"]
        GitHub["GitHub Status"]
    end

    Success --> Slack
    Success --> GitHub
    Failure --> Slack
    Failure --> GitHub
```

### 10.2 通知内容

| イベント | 通知先 | 内容 |
|----------|--------|------|
| CI成功 | GitHub Status | ステータスバッジ更新 |
| CI失敗 | Slack + GitHub | エラー詳細 |
| デプロイ成功 | Slack | 環境・バージョン情報 |
| デプロイ失敗 | Slack | エラー詳細・ロールバック手順 |

---

## 11. ワークフローファイル例

### 11.1 ci.yml（概要）

```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements-dev.txt
        working-directory: app/backend
      - run: pytest --cov --cov-report=xml
        working-directory: app/backend

  backend-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install ruff black
      - run: ruff check .
        working-directory: app/backend
      - run: black --check .
        working-directory: app/backend

  frontend-user-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
        working-directory: app/frontend/user
      - run: npm test -- --coverage
        working-directory: app/frontend/user

  frontend-user-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
        working-directory: app/frontend/user
      - run: npm run lint
        working-directory: app/frontend/user

  # frontend-admin-test, frontend-admin-lint も同様

  terraform-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend=false
        working-directory: app/infra/environments/dev
      - run: terraform validate
        working-directory: app/infra/environments/dev

  migration-validate:
    runs-on: ubuntu-latest
    if: contains(github.event.head_commit.modified, 'migrations/')
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: zousho_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4

      - name: Install dbmate
        run: |
          curl -fsSL https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 \
            -o /usr/local/bin/dbmate
          chmod +x /usr/local/bin/dbmate

      - name: Validate migration file naming
        run: |
          # タイムスタンプ形式チェック (YYYYMMDDHHMMSS_description.sql)
          for f in app/backend/migrations/*.sql; do
            basename "$f" | grep -E '^[0-9]{14}_[a-z_]+\.sql$' || exit 1
          done

      - name: Test migrations with dbmate
        run: |
          dbmate --migrations-dir ./app/backend/migrations up
          dbmate --migrations-dir ./app/backend/migrations rollback
          dbmate --migrations-dir ./app/backend/migrations up
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/zousho_test?sslmode=disable
```

### 11.2 deploy-dev.yml（概要）

```yaml
name: Deploy to Dev

on:
  push:
    branches: [develop]

env:
  AWS_REGION: ap-northeast-1

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - uses: hashicorp/setup-terraform@v3

      # Frontend Build
      - run: npm ci && npm run build
        working-directory: app/frontend/user

      - run: npm ci && npm run build
        working-directory: app/frontend/admin

      # Lambda Package
      - run: |
          pip install -r requirements.txt -t package/
          cd package && zip -r ../lambda.zip .
          cd .. && zip -g lambda.zip -r handlers/ models/ services/
        working-directory: app/backend

      # Terraform Apply
      - run: |
          terraform init
          terraform apply -auto-approve
        working-directory: app/infra/environments/dev

      # DB Migration via CodeBuild
      - name: Run DB Migrations
        run: |
          # CodeBuild 起動
          BUILD_ID=$(aws codebuild start-build \
            --project-name zousho-migration-${{ vars.ENVIRONMENT }} \
            --source-version ${{ github.sha }} \
            --query 'build.id' \
            --output text)

          echo "CodeBuild started: $BUILD_ID"

          # 完了待ち（最大10分）
          for i in {1..60}; do
            STATUS=$(aws codebuild batch-get-builds \
              --ids $BUILD_ID \
              --query 'builds[0].buildStatus' \
              --output text)

            echo "Build status: $STATUS"

            if [ "$STATUS" = "SUCCEEDED" ]; then
              echo "Migration completed successfully"
              break
            elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ]; then
              echo "Migration failed with status: $STATUS"
              exit 1
            fi

            sleep 10
          done

      # S3 Deploy
      - run: |
          aws s3 sync app/frontend/user/dist s3://${{ vars.S3_BUCKET_USER }} --delete
          aws s3 sync app/frontend/admin/dist s3://${{ vars.S3_BUCKET_ADMIN }} --delete

      # CloudFront Invalidation
      - run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ vars.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

### 11.3 buildspec.yml（CodeBuild マイグレーション用）

```yaml
version: 0.2

env:
  secrets-manager:
    DATABASE_URL: zousho-${ENVIRONMENT}/database:url

phases:
  install:
    commands:
      - echo "Installing dbmate..."
      - curl -fsSL https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 -o /usr/local/bin/dbmate
      - chmod +x /usr/local/bin/dbmate
      - dbmate --version

  pre_build:
    commands:
      - echo "Checking database connection..."
      - dbmate --migrations-dir ./app/backend/migrations status

  build:
    commands:
      - echo "Running database migrations..."
      - dbmate --migrations-dir ./app/backend/migrations up
      - echo "Migrations completed successfully"

  post_build:
    commands:
      - echo "Generating schema dump..."
      - dbmate --migrations-dir ./app/backend/migrations dump > schema.sql
      - echo "Migration status:"
      - dbmate --migrations-dir ./app/backend/migrations status

artifacts:
  files:
    - schema.sql
  discard-paths: yes

cache:
  paths:
    - /usr/local/bin/dbmate
```

### 11.4 CodeBuild プロジェクト設定（Terraform）

```hcl
# app/infra/modules/codebuild/main.tf

resource "aws_codebuild_project" "migration" {
  name          = "zousho-migration-${var.environment}"
  description   = "Database migration runner using dbmate"
  build_timeout = 10  # 10分

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repo_url
    git_clone_depth = 1
    buildspec       = "app/backend/buildspec.yml"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = [aws_security_group.codebuild.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/zousho-migration-${var.environment}"
      stream_name = "build-log"
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "database-migration"
  }
}

resource "aws_security_group" "codebuild" {
  name        = "zousho-codebuild-${var.environment}"
  description = "Security group for CodeBuild migration runner"
  vpc_id      = var.vpc_id

  egress {
    description     = "PostgreSQL to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_security_group_id]
  }

  egress {
    description = "HTTPS for external access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "zousho-codebuild-${var.environment}"
    Environment = var.environment
  }
}
```

---

## 12. 今後の拡張計画

### 12.1 Phase 1（初期実装）

- [x] 基本CI（テスト・Lint）
- [x] dev環境自動デプロイ
- [x] prod環境手動承認デプロイ

### 12.2 Phase 2（改善）

- [ ] E2Eテスト（Playwright）
- [ ] カナリアデプロイ
- [ ] 自動ロールバック

### 12.3 Phase 3（高度化）

- [ ] ブルーグリーンデプロイ
- [ ] パフォーマンステスト
- [ ] セキュリティスキャン（SAST/DAST）

---

## 13. 運用ガイドライン

### 13.1 日常運用

| 作業 | 頻度 | 担当 |
|------|------|------|
| ワークフロー監視 | 毎日 | 開発チーム |
| 失敗アラート対応 | 随時 | 開発チーム |
| シークレットローテーション | 90日ごと | インフラ担当 |

### 13.2 トラブルシューティング

| 問題 | 対処法 |
|------|--------|
| テスト失敗 | ログ確認 → ローカル再現 → 修正 |
| デプロイ失敗 | Terraform state確認 → 手動修正 |
| 本番障害 | ロールバック → 原因調査 → 恒久対策 |
