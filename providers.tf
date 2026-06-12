# The default provider configuration; resources that begin with `aws_` will use
# it as the default, and it can be referenced as `aws`.
# Regional WAF resources for API Gateway are state-bound to this alias.
provider "aws" {
  alias  = "us-west-2"
  region = var.region
}

provider "aws" { region = var.region }

# Keep a dedicated east-region alias for resources that must live there.
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Providers - terraform
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
