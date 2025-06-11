variable "api_name" {
  description = "The name of the API Gateway."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the API Gateway custom domain."
  type        = string
}

variable "zone_id" {
  description = "The Route53 hosted zone ID for the domain."
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain."
  type        = string
}

variable "stage_name" {
  description = "The name of the API Gateway stage."
  type        = string
  default     = "prod"
}

variable "wishlist_lambda_name" {
  description = "The name of the Lambda function to inject into the OpenAPI spec."
  type        = string
}

variable "wishlist_lambda_invoke_arn" {
  description = "The Lambda function invoke ARN to inject into the OpenAPI spec."
  type        = string
}
