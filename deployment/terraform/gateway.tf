resource "aws_api_gateway_rest_api" "oauth_redirect" {
  name = "Hubspot-OAuth-Redirect"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "redirect_resource" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  parent_id   = aws_api_gateway_rest_api.oauth_redirect.root_resource_id
  path_part   = "redirect"
}

resource "aws_api_gateway_resource" "confirm_resource" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  parent_id   = aws_api_gateway_rest_api.oauth_redirect.root_resource_id
  path_part   = "confirm"
}

resource "aws_api_gateway_method" "redirect_method" {
  rest_api_id   = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id   = aws_api_gateway_resource.redirect_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "confirm_method" {
  rest_api_id   = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id   = aws_api_gateway_resource.confirm_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "redirect_integration" {
  rest_api_id               = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id               = aws_api_gateway_resource.redirect_resource.id
  http_method               = aws_api_gateway_method.redirect_method.http_method
  integration_http_method   = "POST"
  type                      = "AWS_PROXY"
  uri                       = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.redirect_oauth.arn}/invocations"
}

resource "aws_api_gateway_integration" "confirm_integration" {
  rest_api_id               = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id               = aws_api_gateway_resource.confirm_resource.id
  http_method               = aws_api_gateway_method.confirm_method.http_method
  integration_http_method   = "POST"
  type                      = "AWS_PROXY"
  uri                       = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.redirect_oauth.arn}/invocations"
}

resource "aws_api_gateway_method_response" "response_302" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id = aws_api_gateway_resource.redirect_resource.id
  http_method = aws_api_gateway_method.redirect_method.http_method
  status_code = "302"

  response_parameters = { 
    "method.response.header.location" = true 
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id = aws_api_gateway_resource.confirm_resource.id
  http_method = aws_api_gateway_method.confirm_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.content-type" = true
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on    = [
    "aws_api_gateway_method_response.response_200",
    "aws_api_gateway_method_response.response_302"
  ]

  rest_api_id   = aws_api_gateway_rest_api.oauth_redirect.id
  stage_name    = "dev"
  description   = "Development API to Redirect Hubspot Authorizations."
}