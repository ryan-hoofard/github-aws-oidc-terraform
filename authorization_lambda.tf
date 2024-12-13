variable "authorization_lambda_name" {
  type        = string
  description = "This Lambda verifies CloudFront authorization header passed to HTTP Api Gateway."
  default     = "lab-sdb-lambda-authorization"
}
variable "authorization_lambda_role_name" {
  type        = string
  description = "Authorization Lambda IAM role name."
  default     = "lab-sdb-iam-authorization-lambda-role"
}
variable "authorization_lambda_policy_name" {
  type        = string
  description = "Authorization Lambda IAM policy name."
  default     = "lab-sdb-iam-authorization-lambda-policy"
}

# ===================================
# API needs integration and authorization. Use Lambda service for both.
resource "aws_lambda_function" "authorization_lambda" {
  filename      = "authorization_lambda.zip"
  function_name = var.authorization_lambda_name
  role          = aws_iam_role.authorization_lambda_role.arn
  handler       = "authorization_lambda.lambda_handler" # first part is for the .py file name. second is for the entry function in that file.
  runtime       = "python3.12"

  source_code_hash = data.archive_file.authorization_lambda_code.output_base64sha256

  environment {
    variables = {
      SECRETNAME = aws_secretsmanager_secret.auth_header_secret.name # or var.secret_name
      AWSREGION  = var.aws_region
    }
  }
}

# Create zip folder
data "archive_file" "authorization_lambda_code" {
  type        = "zip"
  source_file = "./authorization_lambda.py"
  output_path = "./authorization_lambda.zip"
}

# You add API trigger to Lambda function by using aws_lambda_permission
resource "aws_lambda_permission" "authorization_lambda_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorization_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Attach API authorizer to Lambda
  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.api_authorizer_lambda.id}"
}

# ===================================
# Authorization Lambda role
resource "aws_iam_role" "authorization_lambda_role" {
  name = var.authorization_lambda_role_name

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
    tag-key = "Authorization lambda"
  }
}

# Authorization Lambda policy
resource "aws_iam_policy" "authorization_lambda_policy" {
  name = var.authorization_lambda_policy_name
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
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.authorization_lambda_name}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : "${aws_secretsmanager_secret.auth_header_secret.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "authorization_policy_attachment" {
  role       = aws_iam_role.authorization_lambda_role.id
  policy_arn = aws_iam_policy.authorization_lambda_policy.arn
}