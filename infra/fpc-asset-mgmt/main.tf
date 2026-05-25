provider "aws" {
  region = "us-west-2"
}

resource "aws_lambda_function" "asset_management" {
  filename      = var.lambda_zip_file
  function_name = "AssetManagement"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "asset_management.handler"

  runtime = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.asset_table.name
    }
  }

  layers = [aws_lambda_layer_version.python_dependencies.arn]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_asset"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_dynamodb_table" "asset_table" {
  name         = "AssetTable"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }
}