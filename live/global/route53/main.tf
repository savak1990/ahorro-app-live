provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "global"
      Project     = "ahorro-app"
      Service     = "ahorro-terraform"
      Terraform   = "true"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "global/route53/terraform.tfstate"
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

resource "aws_route53_record" "parent_a" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "vkdev1.com"
  type    = "A"
  ttl     = 300
  records = ["1.1.1.1"]
}
