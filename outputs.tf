# Output the API Gateway deployment URL
output "api_gateway_url" {
  value = aws_api_gateway_deployment.rest_api_deployment.invoke_url
}

# Output the URL for the POST endpoint
output "api_post_url" {
  value = "${aws_api_gateway_deployment.rest_api_deployment.invoke_url}${var.stage}/upload"
}

# Output the URL for the GET endpoint
output "api_get_url" {
  value = "${aws_api_gateway_deployment.rest_api_deployment.invoke_url}${var.stage}/download"
}


# # Output the URL for the GET endpoint
# output "api_get_url" {
#   value = "${aws_api_gateway_deployment.rest_api_deployment.invoke_url}${var.stage}/get"
# }

# Output the value of the API key, marked as sensitive (terraform output api_key_value)
output "api_key_value" {
  value     = aws_api_gateway_api_key.api_key.value
  sensitive = true
}
