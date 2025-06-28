terraform {
  backend "s3" {
    bucket         = "ahorro-app-state"
    key            = "global/iam/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "ahorro-app-state-lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
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

data "aws_secretsmanager_secret" "ahorro_app" {
  name = "ahorro-app-secrets"
}

data "aws_secretsmanager_secret_version" "ahorro_app" {
  secret_id = data.aws_secretsmanager_secret.ahorro_app.id
}

data "aws_caller_identity" "current" {}

locals {
  group_name  = "ahorro-developers"
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.ahorro_app.secret_string)

  # Get developer users from Secrets Manager - support both formats
  developer_1      = local.secret_data["dev_name_1"]
  default_password = local.secret_data["default_aws_password"]
  account_alias    = local.secret_data["account_alias"]
}

# Create IAM group for Ahorro developers
resource "aws_iam_group" "ahorro_developers" {
  name = local.group_name
  path = "/ahorro/"
}

# Policy that restricts access to Ahorro resources only
resource "aws_iam_policy" "ahorro_development_policy" {
  name        = "ahorro-development-policy"
  path        = "/ahorro/"
  description = "Policy for Ahorro application development access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 access for all ahorro buckets
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::ahorro-*",
          "arn:aws:s3:::ahorro-*/*"
        ]
      },
      # Lambda access for ahorro functions
      {
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "arn:aws:lambda:*:*:function:ahorro-*"
      },
      # API Gateway access for ahorro APIs
      {
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "arn:aws:apigateway:*::/restapis/*"
        Condition = {
          StringLike = {
            "aws:RequestedRegion" = "eu-west-1"
          }
        }
      },
      # RDS access for ahorro databases
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:RebootDBInstance",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:DescribeDBSubnetGroups",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:ModifyDBSubnetGroup"
        ]
        Resource = [
          "arn:aws:rds:*:*:db:ahorro-*",
          "arn:aws:rds:*:*:snapshot:ahorro-*",
          "arn:aws:rds:*:*:subgrp:ahorro-*"
        ]
      },
      # DynamoDB access for ahorro tables
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/ahorro-*"
      },
      # CloudWatch Logs for ahorro services
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/ahorro-*"
      },
      # Secrets Manager for ahorro secrets
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:ahorro-*"
      },
      # Route53 for ahorro domains
      {
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "route53:ChangeResourceRecordSetsNormalizedName" = "*ahorro*"
          }
        }
      },
      # ACM for certificates
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates"
        ]
        Resource = "*"
      },
      # Cognito for ahorro user pools
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:*"
        ]
        Resource = "arn:aws:cognito-idp:*:*:userpool/*"
        Condition = {
          StringLike = {
            "aws:ExistingResourceTag/Project" = "ahorro-app"
          }
        }
      },
      # EC2 for VPC operations (needed for RDS subnet groups)
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:ExistingResourceTag/Project" = "ahorro-app"
          }
        }
      },
      # Self-service IAM permissions for users to manage their own credentials
      {
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser",
          "iam:UpdateUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:GetLoginProfile",
          "iam:UpdateLoginProfile"
        ]
        Resource = [
          "arn:aws:iam::*:user/ahorro/$${aws:username}"
        ]
      },
      # IAM permissions for service roles (limited)
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteRole",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/ahorro-*",
          "arn:aws:iam::*:policy/ahorro-*"
        ]
      },
      # Terraform state access
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/ahorro-app-state-lock"
      },
      # General read permissions for AWS services
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "ahorro-development-policy"
    Project = "ahorro-app"
    Purpose = "Development access policy for Ahorro application"
  }
}

# Attach policy to group
resource "aws_iam_group_policy_attachment" "ahorro_developers_policy" {
  group      = aws_iam_group.ahorro_developers.name
  policy_arn = aws_iam_policy.ahorro_development_policy.arn
}

# Create users and add them to the group
resource "aws_iam_user" "developer_1" {
  name = local.developer_1
  path = "/ahorro/"

  tags = {
    Name    = local.developer_1
    Project = "ahorro-app"
    Role    = "Developer"
  }
}

# Create console access for users with default password
resource "aws_iam_user_login_profile" "developer_1" {
  user                    = aws_iam_user.developer_1.name
  password_reset_required = false # User can use the default password without resetting

  lifecycle {
    ignore_changes = [password_reset_required]
  }
}

# Use AWS CLI to set the desired password after profile creation
resource "null_resource" "set_developer_password" {
  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-login-profile \
        --user-name ${aws_iam_user.developer_1.name} \
        --password "${local.default_password}" \
        --no-password-reset-required
    EOT
  }

  depends_on = [aws_iam_user_login_profile.developer_1]

  triggers = {
    user_name     = aws_iam_user.developer_1.name
    password_hash = sha256(local.default_password)
  }
}

# Add users to the developers group
resource "aws_iam_group_membership" "ahorro_developers" {
  name  = "${local.group_name}-membership"
  users = [aws_iam_user.developer_1.name]
  group = aws_iam_group.ahorro_developers.name
}
