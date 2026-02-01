---
paths: app/backend/**
---

# バックエンド開発ガイド

バックエンド開発に関するガイドです。

## 技術スタック

| 用途 | 技術 |
|------|------|
| Runtime | AWS Lambda (Python 3.12) |
| API | API Gateway |
| Database | Amazon RDS for PostgreSQL |
| Auth | Amazon Cognito (User Pool) |
| テスト | pytest |

## ディレクトリ構成

```
app/
└── backend/
    ├── handlers/       # Lambda ハンドラー（入出力処理）
    ├── models/         # データモデル（Pydantic/SQLAlchemy）
    ├── repositories/   # データアクセス層（DB CRUD操作）
    ├── services/       # ビジネスロジック
    ├── db/             # DB接続設定・セッション管理
    ├── tests/          # pytest テスト
    ├── requirements.txt
    └── requirements-dev.txt
```

## 絶対ルール

### TDD必須

**すべての機能実装は Red-Green-Refactor サイクルに従うこと**

詳細な手順は @.claude/skills/tdd/SKILL.md を参照。

### 禁止事項

- テストを書く前に実装コードを書くこと
- `assert True` のような意味のないアサーション
- テストを通すためだけのハードコーディング
- 本番コードに `if (testMode)` のような条件分岐を入れること

## 開発コマンド

```bash
cd app/backend
pip install -r requirements.txt      # 依存関係インストール
pip install -r requirements-dev.txt  # 開発用依存関係
pytest                               # テスト実行
pytest --cov                         # カバレッジ付きテスト
ruff check .                         # Linter 実行
black .                              # フォーマット
```

## コーディング規約

- Black + Ruff を使用
- 型ヒントを必ず付与
- docstring は Google スタイル
- ファイル名: snake_case

## 参照ドキュメント

- API仕様: @docs/api-specification.md
- テーブル定義: @docs/database-design.md
- APIエンドポイント追加: @.claude/skills/api-endpoint/SKILL.md
- DBマイグレーション: @.claude/skills/db-migration/SKILL.md

## テスト

- 単体テストは各関数ごとに作成
- DB 操作はテスト用の PostgreSQL コンテナを使用
- Lambda ハンドラーは event/context をモックしてテスト
- テストファイルは `test_*.py`
- カバレッジ目標: 新規コード 80% 以上

## 環境変数

```env
DATABASE_URL=          # PostgreSQL 接続文字列
COGNITO_USER_POOL_ID=  # Cognito User Pool ID
```

## セキュリティ要件

- すべての API は Cognito Authorizer で保護すること
- Lambda は VPC 内に配置すること
- 本番環境のシークレットは AWS Secrets Manager で管理すること
