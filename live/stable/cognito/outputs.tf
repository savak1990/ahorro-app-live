output "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client."
  value       = module.cognito.user_pool_client_id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool."
  value       = module.cognito.user_pool_arn
}

output "user_pool_fqdn" {
  description = "The fully qualified domain name for the Cognito User Pool."
  value       = module.cognito.user_pool_fqdn
  sensitive   = true
}
