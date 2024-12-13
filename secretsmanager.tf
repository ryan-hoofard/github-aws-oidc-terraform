variable "secret_name" {
  type        = string
  description = "This secret stores value for custom authentication header added to ClodFront and verified by API Gateway authorizer (authorization Lambda)."
  default     = "sdb/lab/cloudFront/authHeader"
}
variable "secret_key" {
  type        = string
  description = "HEADERVALUE is an arbitrary name which will be used in the rotation Lambda."
  default     = "HEADERVALUE"
}

# ===================================
resource "aws_secretsmanager_secret" "auth_header_secret" {
  name        = var.secret_name
  description = "This secret stores value for custom authentication header added to CloudFront. The header will be used in API Gateway to ensure that all traffic comes from CloudFront."
}

resource "aws_secretsmanager_secret_version" "auth_header_secret_version" {
  secret_id     = aws_secretsmanager_secret.auth_header_secret.id
  secret_string = <<EOF
   {
    "${var.secret_key}": "${random_password.secret_value.result}"
   }
EOF
}

resource "aws_secretsmanager_secret_rotation" "auth_header_rotation" {
  secret_id           = aws_secretsmanager_secret.auth_header_secret.id
  rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn

  rotation_rules {
    automatically_after_days = 30
    # schedule_expression with cron() or rate() expressions
  }
}

resource "random_password" "secret_value" {
  length  = 32
  special = false # default value is true 
  # override_special = "!#$%&*()-_=+[]{}<>:?" # Use your list of special characters if you need to override deafult values. special must be true.
}

