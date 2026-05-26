# ----------------------------
# 1. Database & Storage
# ----------------------------
resource "aws_dynamodb_table" "fpc_intake_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "site_id"
  range_key    = "lead_id"

  attribute { name = "site_id"; type = "S" }
  attribute { name = "lead_id"; type = "S" }
}

resource "aws_s3_bucket" "fpc_artifact_vault" {
  bucket = "fpc-artifact-vault-${var.random_suffix}"
}

# ----------------------------
# 2. Lambda Execution & IAM
# ----------------------------
resource "aws_iam_role" "fpc_lambda_exec_role" {
  name = "fpc_intake_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "fpc_lambda_storage_write" {
  name = "fpc_lambda_storage_write"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["dynamodb:PutItem", "dynamodb:UpdateItem"], Resource = [aws_dynamodb_table.fpc_intake_table.arn] },
      { Effect = "Allow", Action = ["s3:PutObject", "s3:GetObject"], Resource = ["${aws_s3_bucket.fpc_artifact_vault.arn}/*"] }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fpc_lambda_storage_write" {
  role       = aws_iam_role.fpc_lambda_exec_role.name
  policy_arn = aws_iam_policy.fpc_lambda_storage_write.arn
}

resource "aws_iam_role_policy_attachment" "fpc_lambda_logs" {
  role       = aws_iam_role.fpc_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------------------------
# 3. Compute (Lambda)
# ----------------------------
data "archive_file" "fpc_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../services/intake/index.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "fpc_intake_engine" {
  filename         = data.archive_file.fpc_lambda_zip.output_path
  function_name    = "fpc-intake-engine"
  role             = aws_iam_role.fpc_lambda_exec_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  environment {
    variables = {
      DYNAMODB_TABLE  = var.dynamodb_table_name
      ARTIFACT_BUCKET = aws_s3_bucket.fpc_artifact_vault.id
    }
  }
}

# ----------------------------
# 4. API Gateway V2
# ----------------------------
resource "aws_apigatewayv2_api" "fpc_http_api" { name = "fpc-unified-intake-api", protocol_type = "HTTP" }
resource "aws_apigatewayv2_stage" "fpc_api_stage" { api_id = aws_apigatewayv2_api.fpc_http_api.id, name = "prod", auto_deploy = true }
resource "aws_apigatewayv2_integration" "fpc_lambda_integration" {
  api_id           = aws_apigatewayv2_api.fpc_http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.fpc_intake_engine.invoke_arn
}
resource "aws_apigatewayv2_route" "fpc_lead_route" {
  api_id    = aws_apigatewayv2_api.fpc_http_api.id
  route_key = "POST /intake/lead"
  target    = "integrations/${aws_apigatewayv2_integration.fpc_lambda_integration.id}"
}
resource "aws_lambda_permission" "fpc_api_gw_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fpc_intake_engine.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fpc_http_api.execution_arn}/*/*"
}