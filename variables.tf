data "aws_caller_identity" "current" {}

variable "environment" {
  type    = string
  default = "sdb"
}

variable "project_name" {
  type    = string
  default = "lab"
}

variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
}



