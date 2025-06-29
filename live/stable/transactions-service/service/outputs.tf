output "api_url" {
  description = "Base URL for the Transactions Service API"
  value       = module.ahorro_transactions_service.api_url
  sensitive   = true
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.ahorro_transactions_service.api_gateway_id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.ahorro_transactions_service.lambda_function_name
}

output "deployed_version" {
  description = "Currently deployed version"
  value       = local.version
}
