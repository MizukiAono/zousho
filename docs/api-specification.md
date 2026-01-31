# API仕様書

本ドキュメントでは、蔵書管理システムのREST API仕様を定義します。

## 1. 概要

### 1.1 ベースURL

| 環境 | URL |
|------|-----|
| 開発 | `https://api-dev.example.com/v1` |
| 本番 | `https://api.example.com/v1` |

### 1.2 認証

すべてのAPIエンドポイントはAmazon Cognito Authorizerで保護されています。

リクエストヘッダーに以下を含める必要があります：

```
Authorization: Bearer <id_token>
```

### 1.3 共通レスポンス形式

#### 成功時

```json
{
  "data": { ... },
  "message": "Success"
}
```

#### エラー時

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ"
  }
}
```

### 1.4 共通HTTPステータスコード

| コード | 説明 |
|--------|------|
| 200 | 成功 |
| 201 | 作成成功 |
| 400 | リクエスト不正 |
| 401 | 認証エラー |
| 403 | 権限エラー |
| 404 | リソースが見つからない |
| 409 | 競合（例：既に貸出中） |
| 500 | サーバーエラー |

---

## 2. 書籍API (Books)

### 2.1 書籍一覧取得

書籍の一覧を取得します。

**エンドポイント**

```
GET /books
```

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| q | string | No | タイトル・著者名で検索 |
| status | string | No | ステータスでフィルタ（`0`: 貸出可, `1`: 貸出中） |
| page | integer | No | ページ番号（デフォルト: 1） |
| limit | integer | No | 取得件数（デフォルト: 20, 最大: 100） |

**レスポンス (200 OK)**

```json
{
  "data": {
    "books": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "リーダブルコード",
        "author": "Dustin Boswell",
        "isbn": "9784873115658",
        "status": "0",
        "status_label": "貸出可",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "total_pages": 8
    }
  }
}
```

---

### 2.2 書籍詳細取得

指定したIDの書籍詳細を取得します。

**エンドポイント**

```
GET /books/{id}
```

**パスパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| id | UUID | Yes | 書籍ID |

**レスポンス (200 OK)**

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "リーダブルコード",
    "author": "Dustin Boswell",
    "isbn": "9784873115658",
    "status": "0",
    "status_label": "貸出可",
    "current_rental": null,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

**貸出中の場合**

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "リーダブルコード",
    "author": "Dustin Boswell",
    "isbn": "9784873115658",
    "status": "1",
    "status_label": "貸出中",
    "current_rental": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "user_sub": "abc123-def456",
      "borrowed_at": "2024-01-20T14:00:00Z"
    },
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:00:00Z"
  }
}
```

**エラーレスポンス (404 Not Found)**

```json
{
  "error": {
    "code": "BOOK_NOT_FOUND",
    "message": "指定された書籍が見つかりません"
  }
}
```

---

### 2.3 書籍登録（管理者専用）

新しい書籍を登録します。

**エンドポイント**

```
POST /books
```

**リクエストボディ**

```json
{
  "title": "リーダブルコード",
  "author": "Dustin Boswell",
  "isbn": "9784873115658"
}
```

| フィールド | 型 | 必須 | 説明 |
|------------|-----|------|------|
| title | string | Yes | 書籍タイトル（最大255文字） |
| author | string | Yes | 著者名（最大255文字） |
| isbn | string | No | ISBNコード（10桁または13桁） |

**レスポンス (201 Created)**

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "リーダブルコード",
    "author": "Dustin Boswell",
    "isbn": "9784873115658",
    "status": "0",
    "status_label": "貸出可",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  "message": "書籍を登録しました"
}
```

**エラーレスポンス (400 Bad Request)**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力内容に誤りがあります",
    "details": {
      "title": "タイトルは必須です",
      "isbn": "ISBNの形式が不正です"
    }
  }
}
```

---

### 2.4 書籍更新（管理者専用）

既存の書籍情報を更新します。

**エンドポイント**

```
PUT /books/{id}
```

**パスパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| id | UUID | Yes | 書籍ID |

**リクエストボディ**

```json
{
  "title": "リーダブルコード 改訂版",
  "author": "Dustin Boswell",
  "isbn": "9784873115658"
}
```

| フィールド | 型 | 必須 | 説明 |
|------------|-----|------|------|
| title | string | No | 書籍タイトル（最大255文字） |
| author | string | No | 著者名（最大255文字） |
| isbn | string | No | ISBNコード（10桁または13桁） |

**レスポンス (200 OK)**

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "リーダブルコード 改訂版",
    "author": "Dustin Boswell",
    "isbn": "9784873115658",
    "status": "0",
    "status_label": "貸出可",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-16T09:00:00Z"
  },
  "message": "書籍情報を更新しました"
}
```

---

### 2.5 書籍削除（管理者専用）

書籍を削除（論理削除：ステータスを「廃棄」に変更）します。

**エンドポイント**

```
DELETE /books/{id}
```

**パスパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| id | UUID | Yes | 書籍ID |

**レスポンス (200 OK)**

```json
{
  "message": "書籍を削除しました"
}
```

**エラーレスポンス (409 Conflict)**

```json
{
  "error": {
    "code": "BOOK_IN_USE",
    "message": "貸出中の書籍は削除できません"
  }
}
```

---

## 3. 貸出API (Rentals)

### 3.1 貸出登録

書籍を貸出登録します。

**エンドポイント**

```
POST /rentals
```

**リクエストボディ**

```json
{
  "book_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

| フィールド | 型 | 必須 | 説明 |
|------------|-----|------|------|
| book_id | UUID | Yes | 貸出する書籍のID |

**レスポンス (201 Created)**

```json
{
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "book_id": "550e8400-e29b-41d4-a716-446655440000",
    "book": {
      "title": "リーダブルコード",
      "author": "Dustin Boswell"
    },
    "user_sub": "abc123-def456",
    "borrowed_at": "2024-01-20T14:00:00Z",
    "returned_at": null
  },
  "message": "貸出を登録しました"
}
```

**エラーレスポンス (409 Conflict)**

```json
{
  "error": {
    "code": "BOOK_ALREADY_RENTED",
    "message": "この書籍は既に貸出中です"
  }
}
```

---

### 3.2 返却登録

貸出中の書籍を返却します。

**エンドポイント**

```
PUT /rentals/{id}/return
```

**パスパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| id | UUID | Yes | 貸出記録ID |

**レスポンス (200 OK)**

```json
{
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "book_id": "550e8400-e29b-41d4-a716-446655440000",
    "book": {
      "title": "リーダブルコード",
      "author": "Dustin Boswell"
    },
    "user_sub": "abc123-def456",
    "borrowed_at": "2024-01-20T14:00:00Z",
    "returned_at": "2024-01-25T11:30:00Z"
  },
  "message": "返却を登録しました"
}
```

**エラーレスポンス (403 Forbidden)**

```json
{
  "error": {
    "code": "NOT_YOUR_RENTAL",
    "message": "他のユーザーの貸出は返却できません"
  }
}
```

**エラーレスポンス (400 Bad Request)**

```json
{
  "error": {
    "code": "ALREADY_RETURNED",
    "message": "この書籍は既に返却済みです"
  }
}
```

---

### 3.3 自分の貸出履歴取得

ログインユーザーの貸出履歴を取得します。

**エンドポイント**

```
GET /rentals/me
```

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| status | string | No | `active`（貸出中のみ）, `returned`（返却済みのみ） |
| page | integer | No | ページ番号（デフォルト: 1） |
| limit | integer | No | 取得件数（デフォルト: 20, 最大: 100） |

**レスポンス (200 OK)**

```json
{
  "data": {
    "rentals": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "book_id": "550e8400-e29b-41d4-a716-446655440000",
        "book": {
          "title": "リーダブルコード",
          "author": "Dustin Boswell"
        },
        "borrowed_at": "2024-01-20T14:00:00Z",
        "returned_at": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "total_pages": 1
    }
  }
}
```

---

### 3.4 全貸出履歴取得（管理者専用）

全ユーザーの貸出履歴を取得します。

**エンドポイント**

```
GET /rentals
```

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| book_id | UUID | No | 書籍IDでフィルタ |
| user_sub | string | No | ユーザーでフィルタ |
| status | string | No | `active`（貸出中のみ）, `returned`（返却済みのみ） |
| page | integer | No | ページ番号（デフォルト: 1） |
| limit | integer | No | 取得件数（デフォルト: 20, 最大: 100） |

**レスポンス (200 OK)**

```json
{
  "data": {
    "rentals": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "book_id": "550e8400-e29b-41d4-a716-446655440000",
        "book": {
          "title": "リーダブルコード",
          "author": "Dustin Boswell"
        },
        "user_sub": "abc123-def456",
        "borrowed_at": "2024-01-20T14:00:00Z",
        "returned_at": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

---

## 4. エラーコード一覧

| コード | HTTPステータス | 説明 |
|--------|----------------|------|
| VALIDATION_ERROR | 400 | 入力値バリデーションエラー |
| INVALID_ISBN | 400 | ISBN形式が不正 |
| ALREADY_RETURNED | 400 | 既に返却済み |
| UNAUTHORIZED | 401 | 認証が必要 |
| TOKEN_EXPIRED | 401 | トークン期限切れ |
| FORBIDDEN | 403 | 権限不足 |
| NOT_YOUR_RENTAL | 403 | 他ユーザーの貸出への操作 |
| BOOK_NOT_FOUND | 404 | 書籍が見つからない |
| RENTAL_NOT_FOUND | 404 | 貸出記録が見つからない |
| BOOK_ALREADY_RENTED | 409 | 書籍は既に貸出中 |
| BOOK_IN_USE | 409 | 貸出中の書籍は削除不可 |
| INTERNAL_ERROR | 500 | サーバー内部エラー |

---

## 5. 権限一覧

| エンドポイント | 一般ユーザー | 管理者 |
|----------------|--------------|--------|
| GET /books | Yes | Yes |
| GET /books/{id} | Yes | Yes |
| POST /books | No | Yes |
| PUT /books/{id} | No | Yes |
| DELETE /books/{id} | No | Yes |
| POST /rentals | Yes | Yes |
| PUT /rentals/{id}/return | Yes（自分のみ） | Yes（全員） |
| GET /rentals/me | Yes | Yes |
| GET /rentals | No | Yes |
