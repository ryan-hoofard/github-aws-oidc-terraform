variable "rotation_lambda_name" {
  type        = string
  description = "Rotation Lambda name."
  default     = "lab-sdb-lambda-rotate-secret"
}
variable "rotation_lambda_role_name" {
  type        = string
  description = "Rotation Lambda name."
  default     = "lab-sdb-iam-rotate-secret-lambda-role"
}
variable "rotation_lambda_policy_name" {
  type        = string
  description = "Rotation Lambda name."
  default     = "lab-sdb-iam-rotate-secret-lambda-policy"
}

# ===================================
# CloudFront and SecretsManager need a Lambda function that will regularly rotate the secret in both places (CF and SM).
resource "aws_lambda_function" "rotation_lambda" {
  filename      = "rotation_lambda.zip"
  function_name = var.rotation_lambda_name
  role          = aws_iam_role.rotation_lambda_role.arn
  handler       = "rotation_lambda.lambda_handler" # first part is for the .py file name. second is for the entry function in that file.
  runtime       = "python3.12"

  source_code_hash = data.archive_file.rotation_lambda_code.output_base64sha256

  environment {
    variables = {
      CFDISTROID = aws_cloudfront_distribution.cloudfront_distro.id
      HEADERNAME = "x-origin-verify" # key/name of the header added to CloudFront. This will be checked in API authorizer (authorization Lambda)
      ORIGINURL  = aws_apigatewayv2_api.api_gateway.api_endpoint
    }
  }
}

# Create zip folder
data "archive_file" "rotation_lambda_code" {
  type        = "zip"
  source_file = "./rotation_lambda.py"
  output_path = "./rotation_lambda.zip"
}

# Allow SecretsManager to invoke this function
resource "aws_lambda_permission" "rotation_lambda_permission" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"

  source_arn = aws_secretsmanager_secret.auth_header_secret.arn
}

# ===================================
# Rotation Lambda role
resource "aws_iam_role" "rotation_lambda_role" {
  name = var.rotation_lambda_role_name

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
    tag-key = "secret rotation lambda"
  }
}

# Rotation Lambda policy
resource "aws_iam_policy" "rotation_lambda_policy" {
  name = var.rotation_lambda_policy_name
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
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.rotation_lambda_name}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ],
        "Resource" : "${aws_secretsmanager_secret.auth_header_secret.arn}",
      },
      {
        "Action" : [
          "secretsmanager:GetRandomPassword"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
      ,
      {
        "Action" : [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:UpdateDistribution"
        ],
        "Resource" : "${aws_cloudfront_distribution.cloudfront_distro.arn}",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_policy_attachment" {
  role       = aws_iam_role.rotation_lambda_role.id
  policy_arn = aws_iam_policy.rotation_lambda_policy.arn
}
















# secrets data must be run subsequently
# iam.tf ln. 140
# this data must be added after secret was created
# 1) data.aws_secretsmanager_secret.auth_header
# data "aws_secretsmanager_secret" "auth_header" {
#   name = var.auth_header_name
# }
# output "AUTH-HEADER-VALUE" {
#   value = data.aws_secretsmanager_secret.auth_header.arn
# }
# --------
# 2)
# The data source must be added after the secret was created
# Replace "Resource": "*" with "Resource": "${data.aws_secretsmanager_secret.auth_header.arn}"
# resource "aws_iam_policy" "rotation_lambda_iam_policy" {
# --------
# 3)
# I want to populate CF auth header using this code
# Must be used after the secret was created
# temp comment out !!!!!!!!!!!!
# data "aws_secretsmanager_secret" "auth_header_secret" {
#   arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.auth_header_name}"
# }
# data "aws_secretsmanager_secret_version" "current" {
#   secret_id = data.aws_secretsmanager_secret.auth_header_secret.id
# }
# output "SECRET_PROPS" {
# #   value = nonsensitive(data.aws_secretsmanager_secret_version.current)
#   value = data.aws_secretsmanager_secret_version.current
#   sensitive = true
# } data.aws_secretsmanager_secret_version.current