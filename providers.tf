terraform {
  backend "s3" {
    bucket = "${locals.bucket}"
    key    = "${locals.key}"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}