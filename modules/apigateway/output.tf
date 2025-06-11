output "rest_api_id" {
  description = "The ID of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_execution_arn" {
  description = "The execution ARN of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "api_gateway_url" {
  description = "The invoke URL for the API Gateway custom domain."
  value       = "https://${aws_api_gateway_domain_name.this.domain_name}"
}
