resource "aws_s3_bucket" "this" {
  bucket = "ryanh-github-created-bucket-delete"

  tags = {
    Owner       = "Ryan Hoofard"
    Environment = "Sandbox"
  }
}