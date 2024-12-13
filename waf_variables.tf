# variable "waf_web_acl_name" {
#   type        = string
#   description = "HTTP API Gateway name"
#   default     = "lab-sdb-acl-waf"
# }

# variable "acl_default_action" {
#   type        = string
#   description = "The action to perform if none of the rules contained in the WebACL match."
#   default     = "allow"
# }

# variable "managed_rules" {
#   type = list(object({
#     name            = string
#     priority        = number
#     override_action = string
#     # #excluded_rules  = list(string)
#     vendor_name = string
#     rule_action_override = list(object({
#       name          = string
#       action_to_use = string
#     }))
#   }))
#   description = "List of AWS managed WAF rules."
#   default = [
#     {
#       name            = "AWSManagedRulesCommonRuleSet",
#       priority        = 10
#       override_action = "none"
#       ##excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesAmazonIpReputationList",
#       priority        = 20
#       override_action = "none"
#       ##excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesKnownBadInputsRuleSet",
#       priority        = 30
#       override_action = "none"
#       #excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesSQLiRuleSet",
#       priority        = 40
#       override_action = "none"
#       #excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesLinuxRuleSet",
#       priority        = 50
#       override_action = "none"
#       #excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesUnixRuleSet",
#       priority        = 60
#       override_action = "none"
#       #excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     },
#     {
#       name            = "AWSManagedRulesBotControlRuleSet",
#       priority        = 70
#       override_action = "none"
#       #excluded_rules       = []
#       vendor_name          = "AWS"
#       rule_action_override = []
#     }
#   ]
# }

# variable "enable_logging" {
#   type        = bool
#   description = "Whether to associate Logging resource with the WAFv2 ACL."
#   default     = false
# }

# variable "log_destination_arns" {
#   type        = list(string)
#   description = "The Amazon Kinesis Data Firehose, Cloudwatch Log log group, or S3 bucket Amazon Resource Names (ARNs) that you want to associate with the web ACL."
#   default     = []
# }

# variable "tags" {
#   type        = map(string)
#   description = "A mapping of tags to assign to the WAFv2 ACL."
#   default     = {}
# }
