terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "stable/cognito/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "ahorro-app-state-lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "stable"
      Project     = "ahorro-app"
      Service     = "cognito"
      Terraform   = "true"
    }
  }
}

module "cognito" {
  source = "../../../../ahorro-shared/terraform/cognito"

  user_pool_name        = "ahorro-app-stable-user-pool"
  user_pool_client_name = "ahorro-app-stable-client"
}
