resource "aws_s3_bucket" "this" {
  bucket = "ryanh-github-recreated-bucket-delete2"

  tags = {
    Owner       = "Ryan Hoofard"
    Environment = "Sandbox"
  }
}
