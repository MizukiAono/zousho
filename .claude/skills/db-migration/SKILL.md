---
description: データベースマイグレーションを作成する手順ガイド。dbmate を使用したマイグレーション管理。
user_invocable: true
---

# データベースマイグレーション作成スキル

dbmate を使用した PostgreSQL マイグレーションファイルの作成手順ガイドです。

## 前提条件

- @docs/database-design.md でテーブル定義を確認
- ローカル環境に dbmate がインストールされていること
- Docker で PostgreSQL が起動していること

## dbmate のインストール

```bash
# macOS
brew install dbmate

# Linux
curl -fsSL https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 \
  -o /usr/local/bin/dbmate
chmod +x /usr/local/bin/dbmate

# Windows (WSL推奨)
curl -fsSL https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 \
  -o /usr/local/bin/dbmate
chmod +x /usr/local/bin/dbmate
```

## マイグレーションファイルの配置

```
app/
└── backend/
    └── migrations/
        ├── 20240101000000_create_books_table.sql
        ├── 20240101000001_create_rentals_table.sql
        ├── 20240101000002_create_updated_at_trigger.sql
        └── YYYYMMDDHHMMSS_<description>.sql  # 新規追加
```

## 命名規則

### ファイル名

```
{タイムスタンプ14桁}_{操作}_{テーブル名/対象}.sql
```

**例:**
- `20240315120000_add_category_to_books.sql`
- `20240315130000_create_categories_table.sql`
- `20240315140000_add_index_on_rentals_user_sub.sql`

### 操作プレフィックス

| 操作 | 用途 |
|------|------|
| create | 新規テーブル作成 |
| add | カラム/インデックス追加 |
| alter | カラム変更 |
| drop | カラム/テーブル削除 |
| rename | 名前変更 |

## 重要な原則：マイグレーションファイルはイミュータブル

**一度作成・適用したマイグレーションファイルは絶対に編集しないでください。**

### なぜ編集してはいけないのか

マイグレーションファイルは各環境（開発、ステージング、本番）で順番に適用されます。一度適用されたファイルを編集すると：

1. **環境間の不整合** - 既に適用済みの環境ではスキーマが古いまま、新しい環境では編集後のスキーマになる
2. **ロールバック不可** - dbmate は適用済みファイルのハッシュを記録しており、ファイル変更後はロールバックが失敗する
3. **チームメンバーの混乱** - 他の開発者のローカル環境と不整合が発生する

### 正しい対処法

| 状況 | 対処法 |
|------|--------|
| 適用前のファイルにミスを発見 | ファイルを編集してOK |
| 適用後にカラム追加が必要 | 新しいマイグレーションファイルを作成 |
| 適用後にミスを発見 | 修正用の新しいマイグレーションファイルを作成 |
| テーブル定義を変更したい | ALTER TABLE を含む新しいファイルを作成 |

## 作成手順

### Step 1: 新しいマイグレーションファイルを作成

```bash
cd app/backend

# dbmate コマンドで新規ファイル作成（推奨）
dbmate new create_categories_table

# または手動で作成（タイムスタンプは現在時刻）
touch migrations/$(date +%Y%m%d%H%M%S)_create_categories_table.sql
```

### Step 2: マイグレーションファイルを編集

```sql
-- migrate:up
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_name ON categories (name);

COMMENT ON TABLE categories IS 'カテゴリマスタ';
COMMENT ON COLUMN categories.id IS 'カテゴリID';
COMMENT ON COLUMN categories.name IS 'カテゴリ名';

-- migrate:down
DROP TABLE categories;
```

**重要**: `-- migrate:up` と `-- migrate:down` の両方を必ず記載すること。

### Step 3: ローカルで動作確認

```bash
# 環境変数設定（.envファイルに記載も可）
export DATABASE_URL="postgres://postgres:postgres@localhost:5432/zousho_dev?sslmode=disable"

# マイグレーション状態確認
dbmate status

# マイグレーション実行
dbmate up

# ロールバックテスト
dbmate rollback

# 再度適用
dbmate up
```

### Step 4: docs/database-design.md を更新

新しいテーブルやカラムを追加した場合、設計書も更新してください。

## よく使うマイグレーションパターン

### カラム追加

```sql
-- migrate:up
ALTER TABLE books ADD COLUMN publisher VARCHAR(255);
COMMENT ON COLUMN books.publisher IS '出版社';

-- migrate:down
ALTER TABLE books DROP COLUMN publisher;
```

### カラム変更（NOT NULL 追加）

```sql
-- migrate:up
UPDATE books SET isbn = 'unknown' WHERE isbn IS NULL;
ALTER TABLE books ALTER COLUMN isbn SET NOT NULL;

-- migrate:down
ALTER TABLE books ALTER COLUMN isbn DROP NOT NULL;
```

### インデックス追加

```sql
-- migrate:up
CREATE INDEX CONCURRENTLY idx_books_publisher ON books (publisher);

-- migrate:down
DROP INDEX idx_books_publisher;
```

### 外部キー追加

```sql
-- migrate:up
ALTER TABLE books
ADD COLUMN category_id UUID,
ADD CONSTRAINT books_category_id_fkey
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL;

CREATE INDEX idx_books_category_id ON books (category_id);

-- migrate:down
ALTER TABLE books DROP CONSTRAINT books_category_id_fkey;
DROP INDEX idx_books_category_id;
ALTER TABLE books DROP COLUMN category_id;
```

### トリガー追加

```sql
-- migrate:up
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- migrate:down
DROP TRIGGER update_categories_updated_at ON categories;
```

## dbmate コマンド一覧

| コマンド | 説明 |
|----------|------|
| `dbmate new <name>` | 新規マイグレーションファイル作成 |
| `dbmate up` | 未適用のマイグレーションを全て適用 |
| `dbmate rollback` | 直近のマイグレーションを1つロールバック |
| `dbmate status` | マイグレーション状態を表示 |
| `dbmate dump` | 現在のスキーマをダンプ（schema.sql） |
| `dbmate create` | データベース作成 |
| `dbmate drop` | データベース削除 |

## データベース命名規則

| 種別 | 規則 | 例 |
|------|------|-----|
| テーブル名 | snake_case, 複数形 | `books`, `rentals` |
| カラム名 | snake_case | `created_at`, `book_id` |
| 主キー | `id` | `id` |
| 外部キー | `{参照テーブル単数形}_id` | `book_id` |
| インデックス | `idx_{テーブル名}_{カラム名}` | `idx_books_status` |
| 制約 | `{テーブル名}_{制約種別}_{カラム名}` | `books_status_check` |

## チェックリスト

- [ ] 既存の適用済みマイグレーションファイルを編集していない（新規ファイルを作成した）
- [ ] ファイル名がタイムスタンプ形式（YYYYMMDDHHMMSS）である
- [ ] ファイル名が命名規則に従っている
- [ ] `-- migrate:up` セクションが含まれている
- [ ] `-- migrate:down` セクションが含まれている
- [ ] ローカル環境で `dbmate up` を実行した
- [ ] ローカル環境で `dbmate rollback` を実行した（ロールバックテスト）
- [ ] 再度 `dbmate up` で適用できることを確認した
- [ ] docs/database-design.md を更新した
- [ ] 本番環境への影響を考慮した（ロック、パフォーマンス）

## 注意事項

### 本番環境での注意

1. **CONCURRENTLY オプション**: 大きなテーブルへのインデックス追加は `CREATE INDEX CONCURRENTLY` を使用
2. **ロック時間**: ALTER TABLE は短時間で完了するようにする
3. **データ移行**: 大量データの UPDATE は分割実行を検討
4. **バックアップ**: マイグレーション前にRDSスナップショットを取得

### 禁止事項

- 本番環境で直接 SQL を実行しない（必ず dbmate 経由）
- 適用済みのマイグレーションファイルを後から編集しない（新しいファイルを作成）
- `-- migrate:down` セクションを省略しない

## CI/CD での実行

マイグレーションは GitHub Actions から CodeBuild を起動して実行されます。
詳細は @docs/cicd-design.md を参照してください。

```mermaid
flowchart LR
    GHA["GitHub Actions"] --> CB["CodeBuild (VPC内)"]
    CB --> RDS["RDS PostgreSQL"]
    CB -->|"dbmate up"| RDS
```
