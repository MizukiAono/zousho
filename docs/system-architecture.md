# システム構成図

本ドキュメントでは、蔵書管理システムのシステム構成を定義します。

## 1. 全体構成図

```mermaid
flowchart TB
    subgraph Users["ユーザー"]
        User["一般利用者"]
        Admin["管理者"]
    end

    subgraph AWS["AWS Cloud"]
        subgraph Edge["エッジ"]
            CF["CloudFront"]
        end

        subgraph Storage["ストレージ"]
            S3["S3 Bucket<br/>静的コンテンツ"]
        end

        subgraph Auth["認証"]
            Cognito["Cognito<br/>User Pool"]
        end

        subgraph API["APIレイヤー"]
            APIGW["API Gateway"]
        end

        subgraph Compute["コンピュート (VPC内)"]
            subgraph PublicSubnet["Public Subnet"]
                NAT["NAT Gateway"]
            end
            subgraph PrivateSubnet["Private Subnet"]
                Lambda["Lambda<br/>Functions"]
                RDS["RDS<br/>PostgreSQL"]
            end
        end

        subgraph Security["セキュリティ"]
            SM["Secrets Manager"]
        end
    end

    User --> CF
    Admin --> CF
    CF --> S3
    CF --> APIGW
    User --> Cognito
    Admin --> Cognito
    APIGW --> Cognito
    APIGW --> Lambda
    Lambda --> RDS
    Lambda --> SM
    Lambda --> NAT
```

---

## 2. ネットワーク構成

```mermaid
flowchart TB
    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph AZ1["Availability Zone 1"]
            subgraph PublicSubnet1["Public Subnet<br/>10.0.1.0/24"]
                NAT1["NAT Gateway"]
            end
            subgraph PrivateSubnet1["Private Subnet<br/>10.0.10.0/24"]
                Lambda1["Lambda ENI"]
                RDS1["RDS Primary"]
            end
        end

        subgraph AZ2["Availability Zone 2"]
            subgraph PublicSubnet2["Public Subnet<br/>10.0.2.0/24"]
                NAT2["NAT Gateway<br/>(prod only)"]
            end
            subgraph PrivateSubnet2["Private Subnet<br/>10.0.20.0/24"]
                Lambda2["Lambda ENI"]
                RDS2["RDS Standby<br/>(prod only)"]
            end
        end
    end

    IGW["Internet Gateway"] --> PublicSubnet1
    IGW --> PublicSubnet2
    NAT1 --> PrivateSubnet1
    NAT2 --> PrivateSubnet2
```

---

## 3. 認証フロー

```mermaid
sequenceDiagram
    autonumber
    participant User as ユーザー
    participant App as React App
    participant Cognito as Amazon Cognito
    participant APIGW as API Gateway
    participant Lambda as Lambda

    User->>App: ログイン画面アクセス
    App->>Cognito: 認証リクエスト
    Cognito->>User: ログインフォーム表示
    User->>Cognito: 認証情報入力
    Cognito->>App: ID Token / Access Token 返却
    App->>App: Token をローカルストレージに保存

    Note over User,Lambda: API呼び出し時
    App->>APIGW: API リクエスト (Authorization: Bearer <token>)
    APIGW->>Cognito: Token 検証
    Cognito->>APIGW: 検証結果
    APIGW->>Lambda: リクエスト転送 (user_sub 付与)
    Lambda->>APIGW: レスポンス
    APIGW->>App: レスポンス
```

---

## 4. 貸出フロー

```mermaid
sequenceDiagram
    autonumber
    participant User as ユーザー
    participant App as React App
    participant APIGW as API Gateway
    participant Lambda as Lambda
    participant RDS as PostgreSQL

    User->>App: 書籍一覧表示
    App->>APIGW: GET /books
    APIGW->>Lambda: リクエスト
    Lambda->>RDS: SELECT * FROM books
    RDS->>Lambda: 書籍データ
    Lambda->>APIGW: レスポンス
    APIGW->>App: 書籍一覧
    App->>User: 一覧表示

    User->>App: 貸出ボタンクリック
    App->>APIGW: POST /rentals {book_id}
    APIGW->>Lambda: リクエスト
    Lambda->>RDS: BEGIN TRANSACTION
    Lambda->>RDS: SELECT status FROM books WHERE id = ? FOR UPDATE
    RDS->>Lambda: status = '0'
    Lambda->>RDS: INSERT INTO rentals
    Lambda->>RDS: UPDATE books SET status = '1'
    Lambda->>RDS: COMMIT
    Lambda->>APIGW: 201 Created
    APIGW->>App: 貸出完了
    App->>User: 完了メッセージ表示
```

---

## 5. コンポーネント詳細

### 5.1 フロントエンド

| コンポーネント | 説明 |
|----------------|------|
| CloudFront | CDN。S3とAPI Gatewayへのリクエストを配信 |
| S3 | 静的ファイル（HTML/JS/CSS）をホスティング |
| React (User) | 一般利用者向けSPA（Vite + Tailwind CSS） |
| React Admin | 管理者向けSPA（React Admin） |

### 5.2 バックエンド

| コンポーネント | 説明 |
|----------------|------|
| API Gateway | REST API エンドポイント。Cognito Authorizer で認証 |
| Lambda | Python 3.12 でビジネスロジックを実行 |
| RDS PostgreSQL | 書籍・貸出データを永続化 |

### 5.3 認証・セキュリティ

| コンポーネント | 説明 |
|----------------|------|
| Cognito User Pool | ユーザー認証・管理。JWT トークン発行 |
| Secrets Manager | DB 接続情報などの機密情報を管理 |
| IAM | Lambda 実行ロール、最小権限の原則で設定 |

---

## 6. セキュリティグループ

```mermaid
flowchart LR
    subgraph SG_Lambda["Lambda SG"]
        Lambda["Lambda"]
    end

    subgraph SG_RDS["RDS SG"]
        RDS["RDS"]
    end

    Lambda -->|"5432/tcp"| RDS
```

### 6.1 Lambda セキュリティグループ

| ルール | タイプ | ポート | ソース/宛先 |
|--------|--------|--------|-------------|
| Outbound | PostgreSQL | 5432 | RDS SG |
| Outbound | HTTPS | 443 | 0.0.0.0/0 |

### 6.2 RDS セキュリティグループ

| ルール | タイプ | ポート | ソース/宛先 |
|--------|--------|--------|-------------|
| Inbound | PostgreSQL | 5432 | Lambda SG |

---

## 7. 環境別構成

### 7.1 開発環境 (dev)

```mermaid
flowchart TB
    subgraph Dev["開発環境"]
        CF_Dev["CloudFront"]
        S3_Dev["S3"]
        APIGW_Dev["API Gateway"]
        Lambda_Dev["Lambda"]
        RDS_Dev["RDS<br/>db.t3.micro<br/>Single-AZ"]
        Cognito_Dev["Cognito"]
    end

    CF_Dev --> S3_Dev
    CF_Dev --> APIGW_Dev
    APIGW_Dev --> Lambda_Dev
    Lambda_Dev --> RDS_Dev
    APIGW_Dev --> Cognito_Dev
```

| 項目 | 設定 |
|------|------|
| RDS インスタンス | db.t3.micro |
| RDS Multi-AZ | 無効 |
| Lambda メモリ | 256MB |
| CloudFront | 最小キャッシュ |

### 7.2 本番環境 (prod)

```mermaid
flowchart TB
    subgraph Prod["本番環境"]
        CF_Prod["CloudFront<br/>WAF有効"]
        S3_Prod["S3<br/>バージョニング有効"]
        APIGW_Prod["API Gateway<br/>スロットリング有効"]
        Lambda_Prod["Lambda<br/>Provisioned Concurrency"]
        RDS_Prod["RDS<br/>db.t3.small<br/>Multi-AZ"]
        Cognito_Prod["Cognito<br/>MFA有効"]
    end

    CF_Prod --> S3_Prod
    CF_Prod --> APIGW_Prod
    APIGW_Prod --> Lambda_Prod
    Lambda_Prod --> RDS_Prod
    APIGW_Prod --> Cognito_Prod
```

| 項目 | 設定 |
|------|------|
| RDS インスタンス | db.t3.small |
| RDS Multi-AZ | 有効 |
| Lambda メモリ | 512MB |
| Lambda Provisioned Concurrency | 2 |
| CloudFront | WAF 有効 |
| S3 | バージョニング有効 |

---

## 8. デプロイメントパイプライン

```mermaid
flowchart LR
    subgraph Dev["開発"]
        Code["コード<br/>プッシュ"]
    end

    subgraph CI["CI/CD"]
        GitHub["GitHub<br/>Actions"]
        Test["テスト<br/>実行"]
        Build["ビルド"]
    end

    subgraph Deploy["デプロイ"]
        TF["Terraform<br/>Apply"]
        S3Deploy["S3<br/>デプロイ"]
        LambdaDeploy["Lambda<br/>デプロイ"]
    end

    Code --> GitHub
    GitHub --> Test
    Test --> Build
    Build --> TF
    TF --> S3Deploy
    TF --> LambdaDeploy
```

---

## 9. 監視・ログ

### 9.1 監視項目

| サービス | メトリクス | 閾値 |
|----------|------------|------|
| Lambda | Errors | > 0 |
| Lambda | Duration | > 10秒 |
| Lambda | Throttles | > 0 |
| RDS | CPUUtilization | > 80% |
| RDS | FreeStorageSpace | < 1GB |
| API Gateway | 5XXError | > 0 |
| API Gateway | Latency | > 3000ms |

### 9.2 ログ出力先

| サービス | ログ出力先 |
|----------|------------|
| Lambda | CloudWatch Logs |
| API Gateway | CloudWatch Logs |
| RDS | CloudWatch Logs (PostgreSQL) |
| CloudFront | S3 (アクセスログ) |
