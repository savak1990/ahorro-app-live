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

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"

  default_tags {
    tags = {
      Environment = "stable"
      Project     = "ahorro-app"
      Service     = "cognito"
      Terraform   = "true"
    }
  }
}

data "aws_acm_certificate" "cert" {
  provider    = aws.us-east-1
  domain      = "*.${local.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_secretsmanager_secret" "ahorro_app" {
  name = local.secret_name
}

data "aws_secretsmanager_secret_version" "ahorro_app" {
  secret_id = data.aws_secretsmanager_secret.ahorro_app.id
}

data "aws_route53_zone" "public" {
  name = local.domain_name
}

locals {
  secret_name = "ahorro-app-secrets"
  domain_name = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)["domain_name"]
}

module "cognito" {
  source = "github.com/savak1990/ahorro-auth-service//terraform/cognito?ref=v1.0.1"

  user_pool_name        = "ahorro-app-stable-user-pool"
  user_pool_client_name = "ahorro-app-stable-client"
  user_pool_fqdn        = "api-ahorro-auth-stable.${local.domain_name}"
  zone_id               = data.aws_route53_zone.public.id
  acm_certificate_arn   = data.aws_acm_certificate.cert.arn
}
