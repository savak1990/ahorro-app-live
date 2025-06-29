terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "stable/transactions-service/db/terraform.tfstate"
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
      Service     = "transactions-service"
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get CIDR blocks of the subnets where Lambda will run
data "aws_subnet" "lambda_subnets" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  # Application and service names
  app_name     = "ahorro"
  service_name = "transactions"
  env          = "stable"
  base_name    = "${local.app_name}-${local.service_name}-${local.env}"

  # Database configuration
  db_name                  = "${local.app_name}_${local.service_name}_${local.env}_db"
  db_identifier            = "${local.base_name}-db"
  db_instance_class        = "db.t3.micro"
  db_engine_version        = "16.8"
  db_allocated_storage     = 20
  db_max_allocated_storage = 50

  db_subnet_ids = data.aws_subnets.default.ids
  vpc_id        = data.aws_vpc.default.id

  # Extract CIDR blocks from Lambda subnets
  lambda_cidr_blocks = [for subnet in data.aws_subnet.lambda_subnets : subnet.cidr_block]

  secret_name              = "${local.app_name}-app-secrets"
  transactions_db_username = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)["transactions_db_username"]
  transactions_db_password = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)["transactions_db_password"]
}

module "stable_transactions_db" {
  source = "github.com/savak1990/ahorro-transactions-service//terraform/database?ref=build-250629-2059"

  db_identifier   = local.db_identifier
  db_name         = local.db_name
  engine_version  = local.db_engine_version
  master_username = local.transactions_db_username
  master_password = local.transactions_db_password

  # Cost-optimized settings
  instance_class        = local.db_instance_class
  allocated_storage     = local.db_allocated_storage
  max_allocated_storage = local.db_max_allocated_storage

  # Network configuration
  subnet_ids         = local.db_subnet_ids
  vpc_id             = local.vpc_id
  lambda_cidr_blocks = local.lambda_cidr_blocks

  # Temporary public access configuration
  enable_public_access       = true
  allowed_public_cidr_blocks = ["0.0.0.0/0"] # For testing only
}
