terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Render OpenAPI spec from template with Lambda ARN
locals {
  openapi_spec = templatefile("${path.module}/schema/openapi.yml.tmpl", {
    wishlist_lambda_invoke_arn = var.wishlist_lambda_invoke_arn
  })
  fqdn = "${var.api_name}.${var.domain_name}"
}

# Create the API Gateway REST API with inline OpenAPI spec
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.api_name}-rest-api"
  description = "REST API for ${var.api_name}"
  body        = local.openapi_spec

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    openapi_hash = sha256(local.openapi_spec)
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn

  security_policy = "TLS_1_2"
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
}

resource "aws_route53_record" "apigw" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.this.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this.regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "${var.wishlist_lambda_name}-allow-invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.wishlist_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/*"
}
