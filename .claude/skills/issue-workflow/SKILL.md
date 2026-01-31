---
description: GitHub Issue ベースで開発を進める手順ガイド。Issue からブランチ作成、開発、PR 作成までの一貫したワークフロー。
user_invocable: true
---

# Issue ベース開発ワークフロースキル

GitHub Issue を起点とした開発ワークフローの手順ガイドです。

## ワークフロー概要

```
Issue 確認 → ブランチ作成 → 開発（TDD） → コミット → PR 作成 → レビュー → マージ
```

## ブランチ戦略

**@docs/cicd-design.md のブランチ戦略に準拠**

```
main（本番）← develop（開発統合）← feature/*（機能開発）
                                  ← hotfix/*（緊急修正 → main へ直接マージ）
```

| ブランチ | 用途 | マージ先 | デプロイ先 |
|----------|------|----------|------------|
| `main` | 本番リリース | - | prod環境 |
| `develop` | 開発統合 | main | dev環境 |
| `feature/*` | 機能開発 | develop | - |
| `hotfix/*` | 緊急修正 | main, develop | prod環境 |

## 開発手順

### Step 1: Issue を確認

1. Issue の内容を確認する
2. 要件・受け入れ条件を理解する
3. 不明点があれば Issue にコメントで質問する

```bash
# Issue の詳細を確認
gh issue view <issue-number>

# Issue 一覧を確認
gh issue list
```

### Step 2: develop を最新化してブランチを作成

**命名規則**: `feature/<issue-number>-<short-description>`

```bash
# develop ブランチを最新化
git checkout develop
git pull origin develop

# Issue 用のブランチを作成
git checkout -b feature/<issue-number>-<short-description>

# 例: Issue #12 の書籍一覧API実装
git checkout -b feature/12-books-list-api
```

### Step 2b: 緊急修正（hotfix）の場合

本番環境のバグ修正など、緊急対応が必要な場合は `hotfix/*` ブランチを使用。

```bash
# main ブランチから hotfix ブランチを作成
git checkout main
git pull origin main
git checkout -b hotfix/<issue-number>-<short-description>

# 例: Issue #99 の認証バグ緊急修正
git checkout -b hotfix/99-auth-critical-fix
```

### Step 3: 開発（TDD 必須）

**@.claude/skills/testing.md の Red-Green-Refactor サイクルに従う**

1. **Red**: 失敗するテストを書く
2. **Green**: テストを通す最小限のコードを書く
3. **Refactor**: コードを改善する

```bash
# Backend
cd app/backend
pytest -v

# Frontend
cd app/frontend/user
npm run test
```

### Step 4: コミット

**コミットメッセージ規約**（日本語）:

```
<type>: <description>

- 詳細な変更内容1
- 詳細な変更内容2

Refs #<issue-number>
```

| type | 用途 |
|------|------|
| feat | 新機能追加 |
| fix | バグ修正 |
| docs | ドキュメント変更 |
| style | コードスタイル変更 |
| refactor | リファクタリング |
| test | テスト追加・修正 |
| chore | ビルド・設定変更 |

```bash
# 例
git add <files>
git commit -m "feat: 書籍一覧APIを実装

- GET /books エンドポイントを追加
- ページネーション対応
- 検索フィルター対応

Refs #12"
```

**コミットのタイミング**:
- Green（テストが通った時点）でコミット
- Refactor 完了後にコミット
- 論理的な単位でこまめにコミット

### Step 5: リモートにプッシュ

```bash
# 初回プッシュ（upstream 設定）
git push -u origin feature/12-books-list-api

# 2回目以降
git push
```

### Step 6: PR を作成

**feature ブランチ → develop への PR**

```bash
gh pr create \
  --base develop \
  --title "feat: 書籍一覧APIを実装 (#12)" \
  --body "$(cat <<'EOF'
## 概要

<!-- このPRで何を実現するか -->

## 関連 Issue

Closes #<issue-number>

## 変更内容

- 変更点1
- 変更点2
- 変更点3

## テスト方法

1. 手順1
2. 手順2

## チェックリスト

- [ ] テストを書いた（TDD）
- [ ] 既存のテストが通る
- [ ] Lint エラーがない
- [ ] ドキュメントを更新した（必要な場合）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**hotfix ブランチ → main への PR**

```bash
gh pr create \
  --base main \
  --title "fix: 認証処理の緊急修正 (#99)" \
  --body "..."
```

**PR タイトル例**:
- `feat: 書籍一覧APIを実装 (#12)`
- `fix: 貸出処理のバリデーションエラーを修正 (#23)`
- `refactor: 認証ロジックを共通化 (#45)`

### Step 7: CI を確認

PR 作成後、CI が自動実行される。以下が必須:

| チェック項目 | 基準 |
|--------------|------|
| テスト | 全パス |
| カバレッジ | 80%以上 |
| Lint | エラー0 |
| Terraform fmt | 差分なし |

```bash
# PR のチェック状況を確認
gh pr checks
```

### Step 8: レビュー対応

```bash
# レビューコメントを確認
gh pr view --comments

# 修正をコミット
git add <files>
git commit -m "fix: レビュー指摘を修正"
git push

# レビュー再依頼
gh pr ready
```

### Step 9: マージ

**必須条件**（ブランチ保護ルール）:
- [ ] CI パス
- [ ] レビュー承認 1 名以上
- [ ] コンフリクトなし

```bash
# PR をマージ（Squash merge 推奨）
gh pr merge --squash

# ローカルブランチを削除
git checkout develop
git pull origin develop
git branch -d feature/12-books-list-api
```

### Step 10: hotfix 後の develop へのマージ

hotfix を main にマージした後、develop にも反映する。

```bash
# main の変更を develop にマージ
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

## ブランチ命名例

| Issue | ブランチ名 |
|-------|-----------|
| #12 書籍一覧APIを実装 | `feature/12-books-list-api` |
| #23 貸出処理のバグ修正 | `feature/23-rental-validation` |
| #34 READMEを更新 | `feature/34-update-readme` |
| #45 認証ロジックのリファクタリング | `feature/45-auth-logic` |
| #99 本番認証バグ（緊急） | `hotfix/99-auth-critical-fix` |

## リリースフロー

```
feature/* → develop → main（リリース）
                        ↑
            hotfix/* ───┘（緊急時のみ）
```

### develop → main のリリース PR

```bash
gh pr create \
  --base main \
  --head develop \
  --title "Release: v1.0.0" \
  --body "$(cat <<'EOF'
## リリース内容

### 新機能
- #12 書籍一覧API
- #34 ユーザー検索機能

### バグ修正
- #23 貸出処理のバリデーションエラー

### その他
- #45 認証ロジックのリファクタリング
EOF
)"
```

## チェックリスト

### 開発開始前

- [ ] Issue の内容を理解した
- [ ] 要件・受け入れ条件を確認した
- [ ] develop ブランチを最新化した
- [ ] 命名規則に従ったブランチを作成した

### 開発中

- [ ] TDD（Red-Green-Refactor）に従っている
- [ ] こまめにコミットしている
- [ ] コミットメッセージが規約に従っている

### PR 作成前

- [ ] すべてのテストが通る
- [ ] カバレッジが 80% 以上
- [ ] Lint エラーがない
- [ ] 不要なコードやコメントがない
- [ ] セキュリティ上の問題がない

### PR 作成後

- [ ] PR の説明が十分
- [ ] Issue との紐付け（`Closes #<number>`）がある
- [ ] 正しいベースブランチを指定した（feature→develop, hotfix→main）
- [ ] CI がパスしている

## 便利なコマンド

```bash
# Issue から直接ブランチを作成（GitHub CLI）
gh issue develop <issue-number> --checkout

# 現在のブランチに関連する PR を確認
gh pr status

# PR の差分を確認
gh pr diff

# PR のチェック状況を確認
gh pr checks

# develop を取り込む（作業ブランチで）
git fetch origin develop
git rebase origin/develop
```

## 禁止事項

- main / develop ブランチへの直接コミット
- レビューなしのマージ
- CI 未通過でのマージ
- テストなしのコード
- Issue との紐付けのない PR
- Force push（`--force`）の使用（main, develop は設定で禁止）
