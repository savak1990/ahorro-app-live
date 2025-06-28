output "group_name" {
  description = "Name of the Ahorro developers group"
  value       = aws_iam_group.ahorro_developers.name
}

output "group_arn" {
  description = "ARN of the Ahorro developers group"
  value       = aws_iam_group.ahorro_developers.arn
}

output "developer_user" {
  description = "Developer user from Secrets Manager"
  value       = local.developer_1
  sensitive   = true
}

output "created_user" {
  description = "IAM user that was created"
  value       = aws_iam_user.developer_1.name
  sensitive   = true
}

output "group_membership_status" {
  description = "Status of group membership"
  value = {
    group_name   = aws_iam_group.ahorro_developers.name
    member_count = 1
    members      = [aws_iam_user.developer_1.name]
  }
  sensitive = true
}

output "user_console_password" {
  description = "Console password for developer user"
  value = {
    console_alias_url = "https://${local.account_alias}.signin.aws.amazon.com/console"
    account_alias     = local.account_alias
    username          = aws_iam_user.developer_1.name
    password          = local.default_password
  }
  sensitive = true
}

output "console_login_info" {
  description = "Console login information"
  value = {
    console_alias_url = "https://${local.account_alias}.signin.aws.amazon.com/console"
    account_alias     = local.account_alias
    username          = aws_iam_user.developer_1.name
    password          = local.default_password
  }
  sensitive = true
}

output "policy_arn" {
  description = "ARN of the Ahorro development policy"
  value       = aws_iam_policy.ahorro_development_policy.arn
}
