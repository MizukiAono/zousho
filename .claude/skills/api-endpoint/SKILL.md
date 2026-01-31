---
description: 新しいAPIエンドポイントを追加する手順ガイド。Lambda + API Gateway + テストの一貫した追加。
user_invocable: true
---

# API エンドポイント追加スキル

新しい REST API エンドポイントを追加するための手順ガイドです。

## 前提条件

- @docs/api-specification.md で API 仕様を確認
- @docs/database-design.md でデータモデルを確認

## 追加手順

### Step 1: API 仕様を確認・定義

1. エンドポイントのパス（例: `/books`, `/rentals/{id}/return`）
2. HTTP メソッド（GET, POST, PUT, DELETE）
3. リクエストパラメータ（パス、クエリ、ボディ）
4. レスポンス形式（正常系、エラー系）
5. 認可要件（一般ユーザー or 管理者のみ）

### Step 2: テストを書く（Red）

**TDD必須: 実装コードより先にテストを書く**

```python
# app/backend/tests/handlers/test_new_endpoint.py
import pytest
import json
from handlers.new_endpoint import handler

class TestNewEndpoint:
    def test_正常系_データを取得できる(self):
        """正常なリクエストでデータを取得できる"""
        event = {
            "httpMethod": "GET",
            "pathParameters": {"id": "123"},
            "requestContext": {
                "authorizer": {
                    "claims": {"sub": "user-123"}
                }
            }
        }

        response = handler(event, {})

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert "data" in body

    def test_異常系_認証なしで401エラー(self):
        """認証なしのリクエストで401エラーを返す"""
        event = {
            "httpMethod": "GET",
            "pathParameters": {"id": "123"},
            "requestContext": {}
        }

        response = handler(event, {})

        assert response["statusCode"] == 401

    def test_異常系_存在しないIDで404エラー(self):
        """存在しないIDで404エラーを返す"""
        event = {
            "httpMethod": "GET",
            "pathParameters": {"id": "non-existent"},
            "requestContext": {
                "authorizer": {
                    "claims": {"sub": "user-123"}
                }
            }
        }

        response = handler(event, {})

        assert response["statusCode"] == 404
```

テストを実行して失敗を確認:

```bash
cd app/backend
pytest tests/handlers/test_new_endpoint.py -v
```

### Step 3: Lambda ハンドラーを実装（Green）

```python
# app/backend/handlers/new_endpoint.py
import json
from typing import Any
from services.new_service import NewService
from models.response import create_response, create_error_response

def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """新しいエンドポイントのハンドラー"""
    # 認証チェック
    authorizer = event.get("requestContext", {}).get("authorizer", {})
    claims = authorizer.get("claims", {})
    user_sub = claims.get("sub")

    if not user_sub:
        return create_error_response(401, "UNAUTHORIZED", "認証が必要です")

    # パスパラメータ取得
    path_params = event.get("pathParameters", {})
    resource_id = path_params.get("id")

    # HTTPメソッドに応じた処理
    http_method = event.get("httpMethod")

    try:
        service = NewService()

        if http_method == "GET":
            result = service.get(resource_id)
            if not result:
                return create_error_response(404, "NOT_FOUND", "リソースが見つかりません")
            return create_response(200, {"data": result})

        return create_error_response(405, "METHOD_NOT_ALLOWED", "許可されていないメソッドです")

    except Exception as e:
        return create_error_response(500, "INTERNAL_ERROR", str(e))
```

テストを実行して成功を確認:

```bash
pytest tests/handlers/test_new_endpoint.py -v
```

### Step 4: Terraform で API Gateway を設定

```hcl
# app/infra/modules/api_gateway/new_endpoint.tf

# Lambda 関数
resource "aws_lambda_function" "new_endpoint" {
  function_name = "${var.project_name}-new-endpoint-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handlers.new_endpoint.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      DATABASE_URL = var.database_url
    }
  }
}

# API Gateway リソース
resource "aws_api_gateway_resource" "new_resource" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "new-endpoint"
}

# API Gateway メソッド
resource "aws_api_gateway_method" "new_resource_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.new_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Lambda 統合
resource "aws_api_gateway_integration" "new_resource_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.new_resource.id
  http_method             = aws_api_gateway_method.new_resource_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.new_endpoint.invoke_arn
}

# Lambda 実行権限
resource "aws_lambda_permission" "new_endpoint_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_endpoint.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}
```

### Step 5: リファクタリング（Refactor）

1. コードの重複を排除
2. 共通処理を抽出
3. エラーハンドリングを統一
4. テストを再実行して成功を確認

```bash
cd app/backend
pytest -v
ruff check .
black .
```

### Step 6: Terraform の検証

```bash
cd app/infra/environments/dev
terraform fmt -recursive
terraform validate
terraform plan
```

## チェックリスト

- [ ] API 仕様を docs/api-specification.md に追加した
- [ ] テストを先に書いた（Red）
- [ ] テストが失敗することを確認した
- [ ] Lambda ハンドラーを実装した（Green）
- [ ] テストが成功することを確認した
- [ ] リファクタリングした（Refactor）
- [ ] Terraform 設定を追加した
- [ ] `terraform validate` が成功した
- [ ] 正常系テストがある
- [ ] 異常系テスト（401, 403, 404, 500）がある
- [ ] Cognito Authorizer で保護されている

## エラーレスポンス形式

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ"
  }
}
```

## 標準エラーコード

| コード | HTTP Status | 説明 |
|--------|-------------|------|
| VALIDATION_ERROR | 400 | リクエスト不正 |
| UNAUTHORIZED | 401 | 認証エラー |
| FORBIDDEN | 403 | 権限不足 |
| NOT_FOUND | 404 | リソースなし |
| METHOD_NOT_ALLOWED | 405 | メソッド不正 |
| CONFLICT | 409 | 競合エラー |
| INTERNAL_ERROR | 500 | サーバーエラー |
