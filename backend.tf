terraform {
  backend "s3" {
    bucket       = "taaops-terraform-state-oregon"
    key          = "global/lambda-terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
