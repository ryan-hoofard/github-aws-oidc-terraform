# # Add login to CloudFront
# variable "static_webapp_name" {
#   type    = string
#   default = "lab-sdb-s3-static-web-application"
# }
# variable "cloudfront_oac_name" {
#   type    = string
#   default = "lab-sdb-cloudfront-oac"
# }
# variable "s3_origin_name" {
#   type    = string
#   default = "lab-sdb-s3-origin"
# }
# variable "api_origin_name" {
#   type    = string
#   default = "lab-sdb-api-origin"
# }
# # output "cloudfront_distribution_id" {
# #   description = "The identifier for the CloudFront distribution"
# #   value       = aws_cloudfront_distribution.cloudfront_distro.id
# # }

# data "aws_cloudfront_cache_policy" "origin_api" {
#   name = var.aws_cloudfront_cache_policy_api
# }
# data "aws_cloudfront_origin_request_policy" "request_api" {
#   name = var.aws_cloudfront_origin_request_policy_api
# }
# variable "aws_cloudfront_cache_policy_api" {
#   type        = string
#   description = "Name of cloudfront cache policy for API"
#   default     = "Managed-CachingDisabled"
# }
# variable "aws_cloudfront_origin_request_policy_api" {
#   type        = string
#   description = "Name of cloudfront request policy for API"
#   default     = "Managed-AllViewerExceptHostHeader"
# }

# # ===================================
# resource "aws_cloudfront_origin_access_control" "cloudfront_oac" {
#   name                              = var.cloudfront_oac_name
#   description                       = "Default Cloudfront policy for ${var.environment}"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# resource "aws_cloudfront_distribution" "cloudfront_distro" {
#   # S3 origin
#   origin {
#     domain_name              = aws_s3_bucket.static_webapp.bucket_regional_domain_name
#     origin_id                = var.s3_origin_name # or this syntax "${var.project_name}-${var.environment}-ui-origin"
#     origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac.id
#   }

#   # API origin
#   origin {
#     # could also use trim(data.aws_apigatewayv2_api.api_gateway.api_endpoint, "https://")
#     domain_name = replace(aws_apigatewayv2_api.api_gateway.api_endpoint, "/^https?://([^/]*).*/", "$1")
#     origin_id   = var.api_origin_name

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }

#     custom_header {
#       name = "x-origin-verify"
#       # "HEADERVALUE" is the key of the secret
#       value = jsondecode(aws_secretsmanager_secret_version.auth_header_secret_version.secret_string)["HEADERVALUE"]
#     }

#   }

#   enabled             = true
#   is_ipv6_enabled     = true
#   comment             = "Serves UI content from S3. Forwards requests to HTTP API Gateway."
#   default_root_object = "index.html"

#   # uncomment WAF when ready
#   web_acl_id          = aws_wafv2_web_acl.waf_web_acl.arn

#   # S3 behavior
#   default_cache_behavior {
#     allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = var.s3_origin_name # or this syntax "${var.project_name}-${var.environment}-ui-origin"

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     viewer_protocol_policy = "allow-all"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   # API behavior
#   ordered_cache_behavior {
#     path_pattern     = "/api"
#     allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = var.api_origin_name

#     cache_policy_id          = data.aws_cloudfront_cache_policy.origin_api.id
#     origin_request_policy_id = data.aws_cloudfront_origin_request_policy.request_api.id

#     default_ttl = 0
#     min_ttl     = 0
#     max_ttl     = 0

#     # The parameter ForwardedValues cannot be used when a cache policy is associated to the cache behavior
#     # forwarded_values {
#     #   query_string = true
#     #   cookies {
#     #     forward = "all"
#     #   }
#     # }

#     viewer_protocol_policy = "redirect-to-https"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "whitelist"
#       locations        = ["US"]
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   tags = {
#     Name        = var.project_name
#     Environment = var.environment
#   }
# }

# # ===================================
# resource "aws_s3_bucket" "static_webapp" {
#   bucket = var.static_webapp_name
# }

# resource "aws_s3_bucket_website_configuration" "static_webapp_config" {
#   bucket = aws_s3_bucket.static_webapp.bucket

#   index_document {
#     suffix = "index.html"
#   }
#   error_document {
#     key = "error.html"
#   }
# }

# # S3 bucket ACL access
# resource "aws_s3_bucket_ownership_controls" "static_webapp_ocl" {
#   bucket = aws_s3_bucket.static_webapp.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "static_webapp_public_policy" {
#   bucket = aws_s3_bucket.static_webapp.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_acl" "static_webapp_bucket_acl" {
#   bucket = aws_s3_bucket.static_webapp.id

#   depends_on = [
#     aws_s3_bucket_ownership_controls.static_webapp_ocl,
#     aws_s3_bucket_public_access_block.static_webapp_public_policy,
#   ]
#   acl = "private"
# }

# resource "aws_s3_bucket_policy" "allow_cloudfront" {
#   bucket = aws_s3_bucket.static_webapp.id
#   policy = data.aws_iam_policy_document.s3_cloudfront_policy.json
# }

# data "aws_iam_policy_document" "s3_cloudfront_policy" {
#   statement {
#     sid     = "AllowCloudFrontServicePrincipalReadOnly"
#     effect  = "Allow"
#     actions = ["s3:GetObject"]
#     resources = [
#       aws_s3_bucket.static_webapp.arn,
#       "${aws_s3_bucket.static_webapp.arn}/*"
#     ]

#     principals {
#       type        = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values = [
#         aws_cloudfront_distribution.cloudfront_distro.arn
#       ]
#     }
#   }
# }

# # Automatic file upload
# resource "aws_s3_object" "object-upload-html" {
#   for_each     = fileset("upload/", "*.html")
#   bucket       = aws_s3_bucket.static_webapp.bucket # could be through data.aws_s3_bucket.selected-bucket.bucket
#   key          = each.key                           # could be each.value
#   source       = "upload/${each.value}"
#   content_type = "text/html"
#   etag         = filemd5("upload/${each.value}")
# }

# # Another example 
# # Uploads all files from the local "src/dist" directory to a specified AWS S3 bucket.
# # resource "aws_s3_object" "static_file" {
# #   for_each     = fileset(local.dist_dir, "**")
# #   bucket       = aws_s3_bucket.static_website.id
# #   key          = each.key
# #   source       = "${local.dist_dir}/${each.value}"
# #   content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
# #   etag         = filemd5("${local.dist_dir}/${each.value}")
# # }

# # https://medium.com/@walid.karray/mastering-static-website-hosting-on-aws-with-terraform-a-step-by-step-tutorial-5401ccd2f4fb