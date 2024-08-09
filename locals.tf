locals {
    repo_name = split("/",var.repo)[1]
    key = trimsuffix(locals.repo_name, "-terraform") + "/terraform.tfstate"
    bucket = "ryanh-github-oidc-terraform-test" + "-${var.environment}"
}