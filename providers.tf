terraform {
  backend "s3" {
    bucket = "ryanh-github-oidc-terraform-test"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}