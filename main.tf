provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "awscloudresume.org"

}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.s3_bucket.id
  key = "index.html"
  source = "index.html"
  content_type = "text/html"
  etag = filemd5("index.html")
}

resource "aws_s3_object" "image" {
  bucket = aws_s3_bucket.s3_bucket.id
  key = "images/github_PNG40-1417037603.png"
  source = "github_PNG40-1417037603.png"
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.s3_bucket.id
  cors_rule {
    allowed_headers = ["Content-Type"]
    allowed_methods = ["POST", "GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_policy" "allow_access_to_bucket_objects" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.allow_access_to_bucket_objects_policy.json
}

data "aws_iam_policy_document" "allow_access_to_bucket_objects_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::awscloudresume.org/*",
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.basic_dynamodb_table.arn
      }
    ]
  })
}

data "archive_file" "zipped_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "my_lambda" {
  filename      = data.archive_file.zipped_lambda.output_path
  function_name = "lambda_visit_counter"
  role          = aws_iam_role.iam_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  source_code_hash = data.archive_file.zipped_lambda.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name = aws_lambda_function.my_lambda.function_name
  authorization_type = "NONE"
  
}

resource "aws_dynamodb_table" "basic_dynamodb_table" {
  name         = "WebsiteCounter"
  billing_mode = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key     = "page_id"

  attribute {
    name = "page_id"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name = "lambda_api_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age = 3000
    allow_credentials = false
  }
  
}

resource "aws_apigatewayv2_stage" "lambda_api" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  name = "lambda_api_stage"
  auto_deploy = true

}

resource "aws_apigatewayv2_integration" "lambda_api_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_uri = aws_lambda_function.my_lambda.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /test"
  target = "integrations/${aws_apigatewayv2_integration.lambda_api_integration.id}"
}

resource "aws_apigatewayv2_route" "get_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /test"
  target = "integrations/${aws_apigatewayv2_integration.lambda_api_integration.id}"
}

resource "aws_lambda_permission" "lambda_api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}