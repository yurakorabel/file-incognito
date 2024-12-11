# The following code provisions an API Gateway Usage Plan and Usage Plan Key.

# Creates an API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api.id
    stage  = aws_api_gateway_stage.rest_api_stage.stage_name
  }

  quota_settings {
    limit  = var.quota-limit
    period = var.quota-period
  }

  throttle_settings {
    burst_limit = var.burst
    rate_limit  = var.rate
  }
}

# Creates an API Gateway Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
