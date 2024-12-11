# The following code provisions an a AWS REST API Gateway

# Create a REST API Gatewa
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.name}-api"
  description = "API for AWS Lambda"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # # enable binary media types for the API Gateway
  # binary_media_types = ["multipart/form-data"]
}

# Create an API key for the API Gateway
resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.name}-api-key"
}


# ---- Resources ----

# Create a resource for uploading data to the API Gateway
resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "upload"
}

# Create a module to enable CORS for the upload resource
module "upload_cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.rest_api.id
  api_resource_id = aws_api_gateway_resource.upload_resource.id
  allow_methods   = ["POST", "OPTIONS"]
}

module "download_cors" {
  source          = "squidfunk/api-gateway-enable-cors/aws"
  version         = "0.3.3"
  api_id          = aws_api_gateway_rest_api.rest_api.id
  api_resource_id = aws_api_gateway_resource.download_resource.id
  allow_methods   = ["GET", "OPTIONS"]
}

# Create a resource for getting data from the API Gateway (file download)
resource "aws_api_gateway_resource" "download_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "download"
}


# ---- Methods ----

# Create a method for uploading data to the API Gateway
resource "aws_api_gateway_method" "post_method" {
  # api_key_required = true # require an API key to use the method
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.upload_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id


}

# Create a method for getting data from the API Gateway (file download)
resource "aws_api_gateway_method" "get_method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.download_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id

  request_parameters = {
    "method.request.querystring.access_code" = true # Parameter for file access code
  }
}


# ---- Integrations ----

# Define an integration for the POST method of the upload resource
resource "aws_api_gateway_integration" "upload_resource_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.upload_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_file_sharing_lambda.invoke_arn
  # content_handling        = "CONVERT_TO_TEXT"
  # passthrough_behavior    = "WHEN_NO_TEMPLATES"

  # # Define the headers of the request
  # request_parameters = {
  #   "integration.request.header.Accept"       = "'*/*'",
  #   "integration.request.header.Content-Type" = "'method.request.header.Content-Type'"
  # }

  # # Define the request template for the request
  # request_templates = {
  #   "multipart/form-data" = <<EOF
  #   #set($allParams = $input.params())
  #   {
  #     "body" : $input.json('$'),
  #     "params" : {
  #       #foreach($type in $allParams.keySet())
  #         #set($params = $allParams.get($type))
  #       "$type" : {
  #         #foreach($paramName in $params.keySet())
  #           "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
  #           #if($foreach.hasNext),#end
  #         #end
  #       }
  #       #if($foreach.hasNext),#end
  #     }
  #   }
  # EOF
  # }

}

# Define an integration for the GET method of the download resource (file download)
resource "aws_api_gateway_integration" "download_resource_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.download_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.download_file_lambda.invoke_arn

  content_handling     = "CONVERT_TO_TEXT"
  passthrough_behavior = "WHEN_NO_MATCH"
}

# # Define an integration for the GET method of the get resource
# resource "aws_api_gateway_integration" "get_resource_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.rest_api.id
#   resource_id             = aws_api_gateway_resource.get_resource.id
#   http_method             = aws_api_gateway_method.get_method.http_method
#   integration_http_method = "GET" #  Lambda function can only be invoked via POST
#   type                    = "AWS"
#   uri                     = aws_lambda_function.get_lambda_function.invoke_arn
#   content_handling        = "CONVERT_TO_TEXT"
#   passthrough_behavior    = "WHEN_NO_TEMPLATES"

#   # Define the request template for the request
#   request_templates = {
#     "application/json" = <<EOF
# {
#     "username": "$input.params('username')",
#     "filename": "$input.params('filename')"
# }
# EOF
#   }
# }


# ---- Method responses ----

# Define the method response for the POST method of the upload resource
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  # Define the response model for the response
  response_models = {
    "application/json" = "Empty"
  }
}

# Define the method response for the GET method of the download resource
resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.download_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  response_models = {
    "application/octet-stream" = "Empty"
  }
}


# ---- Integration responses ----

# Create API Gateway integration response for POST method
resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.post_method_response.status_code
  depends_on  = [aws_api_gateway_integration.upload_resource_integration]
}

# Define the integration response for the GET method of the download resource
resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.download_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_method_response.get_method_response.status_code
  depends_on  = [aws_api_gateway_integration.download_resource_integration]
}


# ---- Lambda functions permissions ----

# Create Lambda function permission for API Gateway (POST)
resource "aws_lambda_permission" "post_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_file_sharing_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

# Create Lambda function permission for API Gateway (GET)
resource "aws_lambda_permission" "get_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.download_file_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}


# ---- Deployment ----

# Create API Gateway deployment with a trigger for updating on changes
resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_method.get_method.id,
      aws_api_gateway_integration.upload_resource_integration.id,
      aws_api_gateway_integration.download_resource_integration.id,
      aws_api_gateway_method_response.post_method_response,
      aws_api_gateway_method_response.get_method_response,
      aws_api_gateway_integration_response.post_integration_response,
      aws_api_gateway_integration_response.get_integration_response,
      aws_lambda_permission.get_lambda_permission,
      aws_lambda_permission.post_lambda_permission
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway stage for the deployment
resource "aws_api_gateway_stage" "rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = var.stage
}



# # Method Response for CORS
# resource "aws_api_gateway_method_response" "cors_options_response" {
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_resource.upload_resource.id
#   http_method = "OPTIONS"
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Origin"  = true
#   }
# }

# # Integration Response for CORS
# resource "aws_api_gateway_integration_response" "cors_options_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_resource.upload_resource.id
#   http_method = "OPTIONS"
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
#     "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
#     "method.response.header.Access-Control-Allow-Origin"  = "'*'"
#   }
# }

# # Define the OPTIONS method for CORS
# resource "aws_api_gateway_method" "options_method" {
#   authorization = "NONE"
#   http_method   = "OPTIONS"
#   resource_id   = aws_api_gateway_resource.upload_resource.id
#   rest_api_id   = aws_api_gateway_rest_api.rest_api.id
# }
