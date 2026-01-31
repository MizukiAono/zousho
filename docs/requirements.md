# requirements.md

本プロジェクトの要件を定義します。

## 1. 目的

社内で保有する技術本の在庫・貸出状況をデジタル化し、「誰が・何を借りているか」を可視化することで、スムーズな知識共有を支援する。

## 2. ユーザー機能要件

### 2.1 利用者画面 (React)

- **書籍一覧表示**: タイトル、著者、現在のステータス（貸出可能/貸出中）を一覧表示。
- **検索/フィルタリング**: タイトル・著者名での絞り込み。
- **貸出登録**: 貸出可能本を選択し、ワンクリックで貸出を実行。
- **返却登録**: 自分が借用中の本を選択し、ワンクリックで返却を実行。

### 2.2 管理画面 (React Admin)

- **書籍のCRUD管理**: 書籍の新規登録（手入力）、情報修正、削除。
- **貸出ステータス監視**: 全書籍の貸出状況および、借用ユーザーの確認。
- **ユーザー管理**: 貸出履歴とユーザーの紐付け。

## 3. 技術スタック

- **Frontend (User)**: React (Vite) / Tailwind CSS
- **Frontend (Admin)**: React Admin
- **Backend**: AWS Lambda (Python) / API Gateway
- **Database**: Amazon RDS for PostgreSQL
- **Auth**: Amazon Cognito (User Pool)
- **IaC**: Terraform

## 4. データモデル (PostgreSQL)

### 4.1 `books` テーブル

| カラム名 | 型 | 説明 |
| --- | --- | --- |
| id | UUID (PK) | 書籍の一意識別子 |
| title | VARCHAR(255) | 書籍タイトル |
| author | VARCHAR(255) | 著者名 |
| isbn | VARCHAR(13) | ISBNコード (任意) |
| status | CHAR(1) | '0' (貸出可) / '1' (貸出中) / '9' (廃棄) |
| created_at | TIMESTAMP | 登録日 |
| updated_at | TIMESTAMP | 更新日 |

### 4.2 `rentals` テーブル

| カラム名 | 型 | 説明 |
| --- | --- | --- |
| id | UUID (PK) | 貸出記録の一意識別子 |
| book_id | UUID (FK) | 対象書籍のID |
| user_sub | VARCHAR(255) | Cognitoのユーザー識別子(sub) |
| borrowed_at | TIMESTAMP | 貸出日時 |
| returned_at | TIMESTAMP | 返却日時 (返却前はNULL) |

## 5. 非機能要件

- **認証・認可**: すべてのAPIリクエストはCognito Authorizerにより保護される。
- **可用性**: RDSはシングルAZで構成する。
- **拡張性**: サーバーレス構成（Lambda）により、リクエスト数に応じた自動スケーリングを実現。

## 6. インフラ構成

本システムは、AWSのマネージドサービスをフル活用したサーバーレスアーキテクチャで構築する。

### 構成要素の詳細

- **静的コンテンツ配信**: S3にホストされたReactビルドファイルを、CloudFront経由で高速かつ安全に配信。
- **APIレイヤー**: API Gatewayを入口とし、Lambdaでビジネスロジックを実行。
- **ネットワーク (VPC)**:
- RDSはプライベートサブネットに配置し、セキュリティグループでLambdaからのアクセスのみを許可。
- LambdaはVPC内に配置し、RDSとセキュアに通信を行う。


- **セキュリティ**:
- **Cognito**: ユーザー認証を一任。管理画面・一般画面の両方で共通のユーザープールを利用。
- **IAM Role**: LambdaにRDSへのアクセス権限および、最小限の権限を付与。
