# resource "aws_wafv2_web_acl" "waf_web_acl" {
#   name        = var.waf_web_acl_name
#   description = "WAFv2 ACL for Cloudfront"

#   scope = "CLOUDFRONT"

#   default_action {
#     dynamic "allow" {
#       for_each = var.acl_default_action == "allow" ? [1] : []
#       content {}
#     }
#     dynamic "block" {
#       for_each = var.acl_default_action == "block" ? [1] : []
#       content {}
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     sampled_requests_enabled   = true
#     metric_name                = "lab-sdb-${data.aws_caller_identity.current.account_id}" # "${var.owner_name}-${var.env}-${var.aws_id}-${var.uniq_id}"
#   }

#   dynamic "rule" {
#     for_each = var.managed_rules
#     content {
#       name     = rule.value.name
#       priority = rule.value.priority

#       override_action {
#         dynamic "none" {
#           for_each = rule.value.override_action == "none" ? [1] : []
#           content {}
#         }
#         dynamic "count" {
#           for_each = rule.value.override_action == "count" ? [1] : []
#           content {}
#         }
#       }

#       statement {
#         managed_rule_group_statement {
#           name        = rule.value.name
#           vendor_name = rule.value.vendor_name

#           dynamic "rule_action_override" {
#             for_each = rule.value.rule_action_override
#             content {
#               name = rule_action_override.value["name"]
#               action_to_use {
#                 dynamic "allow" {
#                   for_each = rule_action_override.value["action_to_use"] == "allow" ? [1] : []
#                   content {}
#                 }
#                 dynamic "block" {
#                   for_each = rule_action_override.value["action_to_use"] == "block" ? [1] : []
#                   content {}
#                 }
#                 dynamic "count" {
#                   for_each = rule_action_override.value["action_to_use"] == "count" ? [1] : []
#                   content {}
#                 }
#               }
#             }
#           }
#         }
#       }

#       visibility_config {
#         cloudwatch_metrics_enabled = true
#         metric_name                = rule.value.name
#         sampled_requests_enabled   = true
#       }
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Service = "WAF"
#   }
# }

# resource "aws_wafv2_web_acl_logging_configuration" "main" {
#   count = var.enable_logging ? 1 : 0

#   log_destination_configs = var.log_destination_arns
#   resource_arn            = aws_wafv2_web_acl.waf_web_acl.arn
# }