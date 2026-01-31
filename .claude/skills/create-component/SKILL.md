---
description: Reactコンポーネントを作成する手順ガイド。TypeScript + Tailwind + テストの一貫した作成。
user_invocable: true
---

# React コンポーネント作成スキル

React コンポーネントを作成するための手順ガイドです。TDD に従い、テストを先に書きます。

## ディレクトリ構成

```
app/frontend/
├── user/                    # 利用者画面
│   └── src/
│       ├── components/      # 共通コンポーネント
│       │   └── Button/
│       │       ├── Button.tsx
│       │       ├── Button.test.tsx
│       │       └── index.ts
│       ├── pages/           # ページコンポーネント
│       └── hooks/           # カスタム hooks
└── admin/                   # 管理画面
    └── src/
        └── components/
```

## 命名規則

| 種別 | 命名規則 | 例 |
|------|----------|-----|
| コンポーネント | PascalCase | `BookList.tsx` |
| テスト | PascalCase + .test | `BookList.test.tsx` |
| hooks | camelCase (use〜) | `useBooks.ts` |
| ユーティリティ | camelCase | `formatDate.ts` |

## 作成手順

### Step 1: テストを書く（Red）

**TDD必須: コンポーネントより先にテストを書く**

```typescript
// src/components/BookCard/BookCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BookCard } from './BookCard';

const mockBook = {
  id: '1',
  title: 'リーダブルコード',
  author: 'Dustin Boswell',
  status: '0' as const,
};

describe('BookCard', () => {
  it('書籍のタイトルと著者を表示する', () => {
    render(<BookCard book={mockBook} />);

    expect(screen.getByText('リーダブルコード')).toBeInTheDocument();
    expect(screen.getByText('Dustin Boswell')).toBeInTheDocument();
  });

  it('貸出可能な書籍に「貸出」ボタンが表示される', () => {
    render(<BookCard book={mockBook} />);

    expect(screen.getByRole('button', { name: '貸出' })).toBeInTheDocument();
  });

  it('貸出中の書籍に「貸出中」ラベルが表示される', () => {
    const borrowedBook = { ...mockBook, status: '1' as const };
    render(<BookCard book={borrowedBook} />);

    expect(screen.getByText('貸出中')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '貸出' })).not.toBeInTheDocument();
  });

  it('貸出ボタンをクリックするとonBorrowが呼ばれる', async () => {
    const user = userEvent.setup();
    const onBorrow = vi.fn();
    render(<BookCard book={mockBook} onBorrow={onBorrow} />);

    await user.click(screen.getByRole('button', { name: '貸出' }));

    expect(onBorrow).toHaveBeenCalledWith('1');
  });
});
```

テストを実行して失敗を確認:

```bash
cd app/frontend/user
npm run test -- BookCard
```

### Step 2: 型定義を作成

```typescript
// src/types/book.ts
export interface Book {
  id: string;
  title: string;
  author: string;
  isbn?: string;
  status: '0' | '1' | '9';  // 貸出可, 貸出中, 廃棄
}

export interface BookCardProps {
  book: Book;
  onBorrow?: (bookId: string) => void;
}
```

### Step 3: コンポーネントを実装（Green）

```typescript
// src/components/BookCard/BookCard.tsx
import type { BookCardProps } from '../../types/book';

export function BookCard({ book, onBorrow }: BookCardProps) {
  const isAvailable = book.status === '0';

  return (
    <div className="rounded-lg border border-gray-200 p-4 shadow-sm">
      <h3 className="text-lg font-semibold text-gray-900">{book.title}</h3>
      <p className="mt-1 text-sm text-gray-600">{book.author}</p>

      <div className="mt-4">
        {isAvailable ? (
          <button
            onClick={() => onBorrow?.(book.id)}
            className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            貸出
          </button>
        ) : (
          <span className="inline-flex items-center rounded-full bg-yellow-100 px-3 py-1 text-sm font-medium text-yellow-800">
            貸出中
          </span>
        )}
      </div>
    </div>
  );
}
```

### Step 4: エクスポート用 index を作成

```typescript
// src/components/BookCard/index.ts
export { BookCard } from './BookCard';
export type { BookCardProps } from '../../types/book';
```

### Step 5: テストを実行（Green 確認）

```bash
npm run test -- BookCard
```

### Step 6: リファクタリング（Refactor）

1. スタイルの共通化
2. アクセシビリティの改善
3. テストを再実行して成功を確認

```bash
npm run test
npm run lint
npm run format
```

## hooks を含むコンポーネントのテスト

### カスタム hooks のテスト

```typescript
// src/hooks/useBooks.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useBooks } from './useBooks';
import { server } from '../mocks/server';
import { rest } from 'msw';

describe('useBooks', () => {
  it('書籍一覧を取得する', async () => {
    const { result } = renderHook(() => useBooks());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.books).toHaveLength(2);
    expect(result.current.error).toBeNull();
  });

  it('エラー時にエラー状態を返す', async () => {
    server.use(
      rest.get('/api/books', (req, res, ctx) => {
        return res(ctx.status(500));
      })
    );

    const { result } = renderHook(() => useBooks());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).not.toBeNull();
  });
});
```

### カスタム hooks の実装

```typescript
// src/hooks/useBooks.ts
import { useState, useEffect } from 'react';
import type { Book } from '../types/book';

interface UseBooksResult {
  books: Book[];
  isLoading: boolean;
  error: Error | null;
}

export function useBooks(): UseBooksResult {
  const [books, setBooks] = useState<Book[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchBooks = async () => {
      try {
        const response = await fetch('/api/books');
        if (!response.ok) throw new Error('Failed to fetch');
        const data = await response.json();
        setBooks(data.books);
      } catch (e) {
        setError(e instanceof Error ? e : new Error('Unknown error'));
      } finally {
        setIsLoading(false);
      }
    };

    fetchBooks();
  }, []);

  return { books, isLoading, error };
}
```

## MSW でのモック設定

```typescript
// src/mocks/handlers.ts
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/books', (req, res, ctx) => {
    return res(
      ctx.json({
        books: [
          { id: '1', title: 'Book 1', author: 'Author 1', status: '0' },
          { id: '2', title: 'Book 2', author: 'Author 2', status: '1' },
        ],
      })
    );
  }),
];

// src/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

## コンポーネントパターン

### ローディング状態

```typescript
if (isLoading) {
  return <div className="animate-pulse">読み込み中...</div>;
}
```

### エラー状態

```typescript
if (error) {
  return (
    <div className="rounded-md bg-red-50 p-4 text-red-700">
      エラーが発生しました: {error.message}
    </div>
  );
}
```

### 空の状態

```typescript
if (books.length === 0) {
  return (
    <div className="text-center text-gray-500">
      書籍が見つかりません
    </div>
  );
}
```

## チェックリスト

- [ ] テストを先に書いた（Red）
- [ ] テストが失敗することを確認した
- [ ] コンポーネントを実装した（Green）
- [ ] テストが成功することを確認した
- [ ] リファクタリングした（Refactor）
- [ ] 型定義がある（`any` 不使用）
- [ ] アクセシビリティを考慮した（aria属性、セマンティックHTML）
- [ ] 正常系テストがある
- [ ] ローディング状態のテストがある
- [ ] エラー状態のテストがある
- [ ] 空の状態のテストがある
- [ ] ESLint エラーがない
- [ ] Prettier でフォーマット済み

## 禁止事項

- `any` 型の使用
- クラスコンポーネントの使用（関数コンポーネント + hooks を使用）
- インラインスタイルの多用（Tailwind CSS を使用）
- テストのない状態でのマージ
