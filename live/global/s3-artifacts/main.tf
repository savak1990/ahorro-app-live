terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "global/s3-artifacts/terraform.tfstate"
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
      Environment = "global"
      Project     = "ahorro-app"
      Service     = "ahorro-terraform"
      Terraform   = "true"
    }
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "ahorro-artifacts"

  tags = {
    Name        = "Ahorro Public Artifacts"
    Environment = "prod"
  }

  force_destroy = true # Optional: allows destroying bucket even if it contains files
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.artifacts.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::ahorro-artifacts/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.artifacts]
}
