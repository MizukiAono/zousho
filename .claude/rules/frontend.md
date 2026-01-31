---
paths: app/frontend/**
---

# フロントエンド開発ガイド

フロントエンド開発のガイドです。

## 技術スタック

| 用途 | 技術 |
|------|------|
| User Frontend | React (Vite) / TypeScript / Tailwind CSS |
| Admin Frontend | React Admin |
| テスト | Vitest / Testing Library / MSW |

## ディレクトリ構成

```
app/
└── frontend/
    ├── user/           # 利用者画面 (Vite + React)
    │   ├── src/
    │   │   ├── components/
    │   │   ├── hooks/
    │   │   ├── pages/
    │   │   └── services/
    │   └── package.json
    └── admin/          # 管理画面 (React Admin)
       └── package.json
```

## 絶対ルール

### TDD必須

**すべての機能実装は Red-Green-Refactor サイクルに従うこと**

詳細な手順は @.claude/skills/tdd/SKILL.md を参照。

### 禁止事項

- テストを書く前に実装コードを書くこと
- `expect(true).toBe(true)` のような意味のないアサーション
- `any` 型の使用
- クラスコンポーネントの使用

## 開発コマンド

```bash
cd app/frontend/user
npm install          # 依存関係インストール
npm run dev          # 開発サーバー起動
npm run build        # 本番ビルド
npm run test         # Vitest でテスト実行
npm run lint         # ESLint 実行
npm run format       # Prettier でフォーマット
```

## コーディング規約

- ESLint + Prettier を使用
- 関数コンポーネントと hooks を使用
- 型は明示的に定義
- ファイル名: コンポーネントは PascalCase、その他は camelCase

## 参照ドキュメント

- コンポーネント作成: @.claude/skills/create-component/SKILL.md
- TDD手順: @.claude/skills/tdd/SKILL.md

## テスト

- コンポーネントは Testing Library でユーザー視点のテストを書く
- カスタム hooks は `renderHook` でテスト
- API 通信は MSW でモック
- テストファイルは `*.test.tsx` または `*.spec.tsx`
- カバレッジ目標: 新規コード 80% 以上

## 環境変数

```env
VITE_API_URL=          # API Gateway エンドポイント
VITE_COGNITO_USER_POOL_ID=  # Cognito User Pool ID
VITE_COGNITO_CLIENT_ID=     # Cognito App Client ID
```

## API エンドポイント（参照用）

| メソッド | パス | 説明 |
|---------|------|------|
| GET | /books | 書籍一覧取得 |
| GET | /books/{id} | 書籍詳細取得 |
| POST | /books | 書籍登録（管理者） |
| PUT | /books/{id} | 書籍更新（管理者） |
| DELETE | /books/{id} | 書籍削除（管理者） |
| POST | /rentals | 貸出登録 |
| PUT | /rentals/{id}/return | 返却登録 |
| GET | /rentals/me | 自分の貸出履歴 |
