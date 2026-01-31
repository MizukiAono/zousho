# CLAUDE.md

このファイルは Claude Code (claude.ai/claude-code) がコードベースを理解するためのガイドです。

## プロジェクト概要

社内技術本の在庫・貸出管理システム（蔵書管理システム）。「誰が・何を借りているか」を可視化し、スムーズな知識共有を支援する。

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| Frontend (User) | React (Vite) / TypeScript / Tailwind CSS |
| Frontend (Admin) | React Admin |
| Backend | AWS Lambda (Python 3.12) / API Gateway |
| Database | Amazon RDS for PostgreSQL |
| Auth | Amazon Cognito (User Pool) |
| IaC | Terraform |

## ディレクトリ構成

```
zousho/
├── app
│   ├── frontend/          # React アプリケーション
│   │   ├── user/          # 利用者画面 (Vite + React)
│   │   └── admin/         # 管理画面 (React Admin)
│   ├── backend/           # AWS Lambda 関数 (Python)
│   │   ├── handlers/      # Lambda ハンドラー
│   │   ├── models/        # データモデル
│   │   └── tests/         # pytest テスト
│   └── infra/             # Terraform 設定
│       ├── modules/       # 再利用可能なモジュール
│       └── environments/  # 環境別設定 (dev/prod)
└── docs/                  # ドキュメント
```

## コミット規約

コミットメッセージは日本語で記述。以下のプレフィックスを使用：

- `feat:` 新機能追加
- `fix:` バグ修正
- `docs:` ドキュメント変更
- `style:` コードスタイル変更（動作に影響なし）
- `refactor:` リファクタリング
- `test:` テスト追加・修正
- `chore:` ビルド・設定変更

例: `feat: 書籍一覧APIを実装`

## 重要な注意事項

### TDD 必須（最重要）

- **テストを書く前に実装コードを書くことは禁止**
- 機能追加・バグ修正は必ず Red-Green-Refactor サイクルに従う
- テストなしのコードはマージ不可
- 詳細は @.claude/skills/tdd/SKILL.md を参照

### セキュリティ

- すべての API は Cognito Authorizer で保護すること
- RDS はプライベートサブネットに配置し、Lambda からのみアクセス可能にすること
- Lambda は VPC 内に配置すること
- 本番環境のシークレットは AWS Secrets Manager で管理すること
