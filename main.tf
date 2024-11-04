resource "aws_s3_bucket" "this" {
  bucket = "ryanh-github-recreated-bucket-delete"

  tags = {
    Owner       = "Ryan Hoofard"
    Environment = "Sandbox"
  }
}
