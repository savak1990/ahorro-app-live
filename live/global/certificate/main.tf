provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project   = "ahorro-app"
      Service   = "ahorro-terraform"
      Terraform = "true"
    }
  }
}

locals {
  app_name          = "ahorro-app-secrets"
  ahorro_app_secret = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)
  domain_name       = local.ahorro_app_secret["domain_name"]
}

# Fetch domain name from AWS Secrets Manager

data "aws_secretsmanager_secret" "ahorro_app" {
  name = local.app_name
}

data "aws_secretsmanager_secret_version" "ahorro_app" {
  secret_id = data.aws_secretsmanager_secret.ahorro_app.id
}

data "aws_route53_zone" "this" {
  name         = local.domain_name
  private_zone = false
}

# Create ACM certificate for the domain (wildcard)
resource "aws_acm_certificate" "single" {
  domain_name       = "*.${local.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS validation records for ACM
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.single.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      zone  = data.aws_route53_zone.this.id
      value = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = each.value.zone
  ttl     = 60
  records = [each.value.value]
}

terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "global/certificate/terraform.tfstate"
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

