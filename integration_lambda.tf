variable "intergation_lambda_name" {
  type        = string
  description = "This Lambda provides a simple response to CloudFront through HTTP Api Gateway. Should be replaced with backend API."
  default     = "lab-sdb-lambda-sample-website"
}
variable "intergation_lambda_role_name" {
  type        = string
  description = "Integration Lambda IAM role name."
  default     = "lab-sdb-iam-integration-lambda-role"
}
variable "intergation_lambda_policy_name" {
  type        = string
  description = "Integration Lambda IAM policy name."
  default     = "lab-sdb-iam-integration-lambda-policy"
}

# ===================================
# API requires integration and authorization. Use Lambda service for both. As an option, use custom URI for integration.
resource "aws_lambda_function" "integration_lambda" {
  filename      = "integration_lambda.zip"
  function_name = var.intergation_lambda_name
  role          = aws_iam_role.integration_lambda_role.arn
  handler       = "integration_lambda.lambda_handler" # first part is for the .py file name. second is for the entry function in that file.
  runtime       = "python3.12"

  source_code_hash = data.archive_file.integration_lambda_code.output_base64sha256
}

# Create zip folder
data "archive_file" "integration_lambda_code" {
  type        = "zip"
  source_file = "./integration_lambda.py"
  output_path = "./integration_lambda.zip"
}

# You add API trigger to Lambda function by using aws_lambda_permission
resource "aws_lambda_permission" "integration_lambda_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.integration_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path within API Gateway
  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
}

# ===================================
# Integration Lambda role
resource "aws_iam_role" "integration_lambda_role" {
  name = var.intergation_lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    tag-key = "simple response lambda"
  }
}

# Integration Lambda policy
resource "aws_iam_policy" "integration_lambda_policy" {
  name = var.intergation_lambda_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.intergation_lambda_name}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "integration_policy_attachment" {
  role       = aws_iam_role.integration_lambda_role.id
  policy_arn = aws_iam_policy.integration_lambda_policy.arn
}