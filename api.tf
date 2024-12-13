variable "api_name" {
  type        = string
  description = "HTTP API Gateway name"
  default     = "lab-sdb-http-api-gateway"
}
variable "api_loggroup_name" {
  type        = string
  description = "HTTP API Gateway name"
  default     = "/aws/lambda/lab-http-api-gateway-logs"
}
variable "api_authorizer_name" {
  type        = string
  description = "This authorizer verifies if requests come from CloudFront"
  default     = "lab-sdb-api-authorizer"
}

# =============================================
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "api_gateway_route" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  # this route is integrated with integration Lambda which represents your backend
  route_key = "GET /api"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration_lambda.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer_lambda.id
  authorization_type = "CUSTOM"
}

# you must have a default stage
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  auto_deploy = true
  name        = "$default"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_log_group.arn

    #  AWS default properties:
    # format = {
    #     "requestId":"$context.requestId", 
    #     "extendedRequestId":"$context.extendedRequestId",
    #     "ip": "$context.identity.sourceIp", 
    #     "caller":"$context.identity.caller", 
    #     "user":"$context.identity.user", 
    #     "requestTime":"$context.requestTime", 
    #     "httpMethod":"$context.httpMethod", 
    #     "resourcePath":"$context.resourcePath", 
    #     "status":"$context.status", 
    #     "protocol":"$context.protocol", 
    #     "responseLength":"$context.responseLength" 
    # }

    format = jsonencode({
      requestId   = "$context.requestId"
      ip          = "$context.identity.sourceIp"
      caller      = "$context.identity.caller"
      user        = "$context.identity.user"
      requestTime = "$context.requestTime"
      method      = "$context.httpMethod"
      status      = "$context.status"
    })
  }
}

resource "aws_apigatewayv2_integration" "api_integration_lambda" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "This Lambda represents your backend that stands behind API"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.integration_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  payload_format_version = "2.0"
}

# CloudWatch log group for API default stage
resource "aws_cloudwatch_log_group" "api_log_group" {
  name = var.api_loggroup_name

  tags = {
    Environment = var.environment
    Application = var.project_name
  }
}

resource "aws_apigatewayv2_authorizer" "api_authorizer_lambda" {
  api_id                            = aws_apigatewayv2_api.api_gateway.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorization_lambda.invoke_arn
  identity_sources                  = ["$request.header.x-origin-verify"] # "x-origin-verify" is a custom header name
  name                              = var.api_authorizer_name
  authorizer_payload_format_version = "2.0"
}
