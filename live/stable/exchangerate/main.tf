terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "stable/exchangerate-cooker/terraform.tfstate"
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
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "stable"
      Project     = "ahorro-app"
      Service     = "ahorro-exchangerate-cooker"
      Terraform   = "true"
    }
  }
}

data "aws_secretsmanager_secret" "ahorro_app" {
  name = local.secret_name
}

data "aws_secretsmanager_secret_version" "ahorro_app" {
  secret_id = data.aws_secretsmanager_secret.ahorro_app.id
}

# Local variables
locals {
  app_name       = "ahorro"
  component_name = "exchangerate"
  env            = "stable"
  base_name      = "${local.app_name}-${local.component_name}-${local.env}"
  secret_name    = "${local.app_name}-app-secrets"

  # S3 configuration for Lambda package
  s3_bucket_name = "ahorro-artifacts"
  s3_key         = "${local.component_name}/savak/exchangerate-lambda.zip"
}

# Main exchange rate cooker module
module "exchange_rate_cooker" {
  source = "git::https://github.com/savak1990/ahorro-exchangerate-cooker.git//terraform?ref=v1.0.1"

  base_name               = local.base_name
  app_s3_bucket_name      = local.s3_bucket_name
  app_s3_artifact_zip_key = local.s3_key
  exchange_rate_api_key   = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)["exchange_rate_api_key"]
  schedule_expression     = "cron(10 0 * * ? *)" // Once a day at 00:10 UTC
  #schedule_expression  = "rate(5 minutes)" // Every 5 minutes for testing
  supported_currencies = ["USD", "JPY", "CAD", "AUD", "CNY", "EUR", "GBP", "CHF", "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "RON", "UAH", "BYN", "RUB"]
  ttl_interval_days    = 30
}
