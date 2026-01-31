---
description: TDD（テスト駆動開発）の手順ガイド。新機能実装やバグ修正時に使用。
user_invocable: true
---

# TDD（テスト駆動開発）スキル

このスキルはテスト駆動開発の手順を強制し、品質の高いコードを作成するためのガイドです。

## 使用タイミング

- 新機能を実装するとき
- バグを修正するとき
- 既存機能を変更するとき

## Red-Green-Refactor サイクル

### Step 1: Red（失敗するテストを書く）

**実装コードより先にテストを書く**

1. 実装したい機能の仕様を確認する
2. その機能をテストするコードを書く
3. テストを実行し、**失敗することを確認**する
4. 失敗理由が期待通りであることを確認する

```bash
# Backend (Python)
cd app/backend
pytest -v

# Frontend (TypeScript)
cd app/frontend/user
npm run test
```

> **コミット: しない** - テストが失敗する状態はCIを壊すため、コミットしない

### Step 2: Green（テストを通す最小限のコードを書く）

**テストを通すために必要最小限のコードのみを実装する**

1. テストを通すための実装コードを書く
2. この段階では完璧なコードを目指さない
3. テストを実行し、**成功することを確認**する

```bash
# Backend
pytest -v

# Frontend
npm run test
```

> **コミット: する** - 動く状態の最小単位。Refactorで問題が発生した場合の安全なロールバックポイント
>
> ```bash
> git commit -m "feat: 書籍一覧APIを実装"
> ```

### Step 3: Refactor（リファクタリング）

**テストが通る状態を維持しながらコードを改善する**

1. 重複を排除する
2. 可読性を向上させる
3. パフォーマンスを改善する
4. テストを実行し、**依然として成功することを確認**する

```bash
# Backend
pytest -v
ruff check .
black .

# Frontend
npm run test
npm run lint
```

> **コミット: する** - 品質を担保した最終状態を記録
>
> ```bash
> git commit -m "refactor: 書籍一覧APIのコード改善"
> ```
>
> ※ 変更が小さい場合は、Green でコミットせず Refactor 完了後に1回だけコミットでも可

## 禁止事項（絶対に守ること）

- `assert True` や `expect(true).toBe(true)` のような意味のないアサーション
- テストを通すためだけのハードコーディング
- 本番コードに `if (testMode)` のような条件分岐を入れること
- カバレッジのためだけの形式的なテスト
- テスト用のマジックナンバーを本番コードに埋め込むこと

## テストの書き方

### Backend (Python / pytest)

```python
# tests/test_books_handler.py
import pytest
import json
from handlers.books import get_books

def test_get_books_returns_list():
    """書籍一覧を取得できる"""
    event = {"httpMethod": "GET"}
    context = {}

    response = get_books(event, context)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "books" in body
    assert isinstance(body["books"], list)

def test_get_books_with_invalid_method_returns_405():
    """無効なHTTPメソッドで405エラーを返す"""
    event = {"httpMethod": "POST"}
    context = {}

    response = get_books(event, context)

    assert response["statusCode"] == 405
```

### Frontend (TypeScript / Vitest)

```typescript
// src/components/BookList.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BookList } from './BookList';

describe('BookList', () => {
  it('書籍一覧を表示する', async () => {
    render(<BookList />);

    expect(await screen.findByText('本のタイトル')).toBeInTheDocument();
  });

  it('貸出ボタンをクリックすると貸出処理が実行される', async () => {
    const user = userEvent.setup();
    render(<BookList />);

    const button = await screen.findByRole('button', { name: '貸出' });
    await user.click(button);

    expect(await screen.findByText('貸出中')).toBeInTheDocument();
  });
});
```

## テストカバレッジ目標

| 対象 | 目標 |
|------|------|
| 新規コード | 80% 以上 |
| クリティカルパス | 100% |
| エッジケース・異常系 | 必須 |

## 必須テストケース

各機能について以下のケースをテストすること：

1. **正常系**: 期待通りの入力で期待通りの出力
2. **境界値**: 最小値、最大値、空、null
3. **異常系**: 無効な入力、エラー状態
4. **エッジケース**: 特殊な状況、競合状態

## チェックリスト

実装完了前に以下を確認：

- [ ] テストを先に書いた（Red）
- [ ] テストが失敗することを確認した
- [ ] 最小限の実装でテストを通した（Green）
- [ ] リファクタリングした（Refactor）
- [ ] 正常系のテストがある
- [ ] 異常系のテストがある
- [ ] 境界値のテストがある
- [ ] カバレッジが80%以上ある
- [ ] 意味のないアサーションがない
- [ ] ハードコーディングがない
