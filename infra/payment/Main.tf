# ----------------------------
# 1. Database & Ledger
# ----------------------------
resource "aws_dynamodb_table" "global_payment_ledger" {
  name         = "global-payment-ledger"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  attribute { name = "PK"; type = "S" }
}

# ----------------------------
# 2. Compute & Security
# ----------------------------
resource "aws_iam_role" "payment_lambda_role" {
  name = "payment_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "payment_lambda_policy" {
  name = "payment_lambda_core_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["dynamodb:PutItem"], Resource = [aws_dynamodb_table.global_payment_ledger.arn] },
      { Effect = "Allow", Action = ["ssm:GetParameter"], Resource = ["arn:aws:ssm:*:*:parameter/payments/*"] },
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "payment_attach" {
  role       = aws_iam_role.payment_lambda_role.name
  policy_arn = aws_iam_policy.payment_lambda_policy.arn
}

resource "aws_ssm_parameter" "unified_payment_routing" {
  name  = "/payments/home_services_routing"
  type  = "SecureString"
  value = jsonencode(var.home_services_routing)
}

data "archive_file" "payment_zip" {
  type        = "zip"
  source_file = "${path.module}/../../services/payment/payment_engine.py"
  output_path = "${path.module}/payment_lambda.zip"
}

resource "aws_lambda_function" "payment_processor" {
  filename         = data.archive_file.payment_zip.output_path
  function_name    = "payment-processor"
  role             = aws_iam_role.payment_lambda_role.arn
  handler          = "payment_engine.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.payment_zip.output_base64sha256
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.global_payment_ledger.name
      SSM_ROUTING_PATH    = aws_ssm_parameter.unified_payment_routing.name
    }
  }
}

# ----------------------------
# 3. API Gateway V2
# ----------------------------
resource "aws_apigatewayv2_api" "payment_gateway" {
  name          = "payment-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.payment_gateway.id
  name        = "prod"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }
}

resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id           = aws_apigatewayv2_api.payment_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.payment_processor.invoke_arn
}

resource "aws_apigatewayv2_route" "deposit" {
  api_id    = aws_apigatewayv2_api.payment_gateway.id
  route_key = "ANY /v1/deposit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.payment_gateway.execution_arn}/*/*"
}

output "payment_api_endpoint" {
  description = "The HTTP API endpoint for your payment gateway"
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/v1/deposit"
}

output "ledger_table_arn" {
  description = "The DynamoDB ledger table"
  value       = aws_dynamodb_table.global_payment_ledger.arn
}