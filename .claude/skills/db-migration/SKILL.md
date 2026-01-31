---
description: データベースマイグレーションを作成する手順ガイド。命名規則、テスト方法を含む。
user_invocable: true
---

# データベースマイグレーション作成スキル

PostgreSQL のマイグレーションファイルを作成するための手順ガイドです。

## 前提条件

- @docs/database-design.md でテーブル定義を確認
- 既存のマイグレーションファイルの連番を確認

## マイグレーションファイルの配置

```
app/
└── backend/
    └── migrations/
        ├── 001_create_books_table.sql
        ├── 002_create_rentals_table.sql
        ├── 003_create_updated_at_trigger.sql
        └── NNN_<description>.sql  # 新規追加
```

## 命名規則

### ファイル名

```
{連番3桁}_{操作}_{テーブル名/対象}.sql
```

**例:**
- `004_add_category_to_books.sql`
- `005_create_categories_table.sql`
- `006_add_index_on_rentals_user_sub.sql`
- `007_alter_books_add_publisher.sql`

### 操作プレフィックス

| 操作 | 用途 |
|------|------|
| create | 新規テーブル作成 |
| add | カラム/インデックス追加 |
| alter | カラム変更 |
| drop | カラム/テーブル削除 |
| rename | 名前変更 |

## 作成手順

### Step 1: 次の連番を確認

```bash
ls app/backend/migrations/
# 最後のファイルの連番 + 1 を使用
```

### Step 2: マイグレーションファイルを作成

```sql
-- Migration: NNN_description.sql
-- 作成日: YYYY-MM-DD
-- 説明: マイグレーションの目的を簡潔に記述

-- ============================================
-- UP: マイグレーション実行
-- ============================================

-- テーブル作成の場合
CREATE TABLE new_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- インデックス作成
CREATE INDEX idx_new_table_name ON new_table (name);

-- コメント追加
COMMENT ON TABLE new_table IS 'テーブルの説明';
COMMENT ON COLUMN new_table.id IS 'カラムの説明';

-- ============================================
-- DOWN: ロールバック用（コメントで記載）
-- ============================================
-- DROP TABLE new_table;
```

### Step 3: SQL 構文を検証

```bash
# ローカル PostgreSQL で構文チェック
psql -h localhost -U postgres -d zousho_test -f migrations/NNN_description.sql

# または Docker コンテナで実行
docker exec -i zousho-db psql -U postgres -d zousho_test < migrations/NNN_description.sql
```

### Step 4: テスト用データで動作確認

```bash
# テストデータベースにマイグレーション適用
psql -h localhost -U postgres -d zousho_test -f migrations/NNN_description.sql

# テーブル構造確認
psql -h localhost -U postgres -d zousho_test -c "\d new_table"

# ロールバックテスト
psql -h localhost -U postgres -d zousho_test -c "DROP TABLE new_table;"
```

### Step 5: docs/database-design.md を更新

新しいテーブルやカラムを追加した場合、設計書も更新してください。

## よく使うマイグレーションパターン

### カラム追加

```sql
-- Migration: 004_add_publisher_to_books.sql
ALTER TABLE books ADD COLUMN publisher VARCHAR(255);

COMMENT ON COLUMN books.publisher IS '出版社';

-- DOWN: ALTER TABLE books DROP COLUMN publisher;
```

### カラム変更（NOT NULL 追加）

```sql
-- Migration: 005_make_isbn_not_null.sql
-- 既存データを更新
UPDATE books SET isbn = 'unknown' WHERE isbn IS NULL;

-- NOT NULL 制約追加
ALTER TABLE books ALTER COLUMN isbn SET NOT NULL;

-- DOWN: ALTER TABLE books ALTER COLUMN isbn DROP NOT NULL;
```

### インデックス追加

```sql
-- Migration: 006_add_index_on_books_publisher.sql
CREATE INDEX CONCURRENTLY idx_books_publisher ON books (publisher);

-- DOWN: DROP INDEX idx_books_publisher;
```

### 外部キー追加

```sql
-- Migration: 007_add_category_fk_to_books.sql
ALTER TABLE books
ADD COLUMN category_id UUID,
ADD CONSTRAINT books_category_id_fkey
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL;

CREATE INDEX idx_books_category_id ON books (category_id);

-- DOWN:
-- ALTER TABLE books DROP CONSTRAINT books_category_id_fkey;
-- ALTER TABLE books DROP COLUMN category_id;
```

### トリガー追加

```sql
-- Migration: 008_add_updated_at_trigger_to_new_table.sql
CREATE TRIGGER update_new_table_updated_at
    BEFORE UPDATE ON new_table
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- DOWN: DROP TRIGGER update_new_table_updated_at ON new_table;
```

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

- [ ] 連番が正しい（既存の最大値 + 1）
- [ ] ファイル名が命名規則に従っている
- [ ] UP（実行）のSQLが含まれている
- [ ] DOWN（ロールバック）のSQLがコメントで含まれている
- [ ] ローカル環境でテスト実行した
- [ ] ロールバックもテストした
- [ ] docs/database-design.md を更新した
- [ ] 本番環境への影響を考慮した（ロック、パフォーマンス）

## 注意事項

### 本番環境での注意

1. **CONCURRENTLY オプション**: 大きなテーブルへのインデックス追加は `CREATE INDEX CONCURRENTLY` を使用
2. **ロック時間**: ALTER TABLE は短時間で完了するようにする
3. **データ移行**: 大量データの UPDATE は分割実行を検討
4. **バックアップ**: マイグレーション前にスナップショットを取得

### 禁止事項

- 本番環境で直接 SQL を実行しない
- マイグレーションファイルを後から編集しない（新しいファイルを作成）
- 連番を飛ばさない
