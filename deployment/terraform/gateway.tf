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

resource "aws_api_gateway_method" "redirect_method" {
  rest_api_id   = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id   = aws_api_gateway_resource.redirect_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "redirect_integration" {
  rest_api_id               = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id               = aws_api_gateway_resource.redirect_resource.id
  http_method               = aws_api_gateway_method.redirect_method.http_method
  integration_http_method   = "POST"
  type                      = "AWS"
  uri                       = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.redirect_oauth.arn}/invocations"
}

resource "aws_api_gateway_method_response" "response_301" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id = aws_api_gateway_resource.redirect_resource.id
  http_method = aws_api_gateway_method.redirect_method.http_method
  status_code = "301"

  response_parameters = { 
      "method.response.header.Location" = true 
  }
}

resource "aws_api_gateway_integration_response" "redirect_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.oauth_redirect.id
  resource_id = aws_api_gateway_resource.redirect_resource.id
  http_method = aws_api_gateway_method.redirect_method.http_method
  status_code = aws_api_gateway_method_response.response_301.status_code

  response_parameters = { 
      "method.response.header.Location" = "integration.response.header.location" 
  }
}

resource "aws_api_gateway_deployment" "redirect_deployment" {
  depends_on    = ["aws_api_gateway_integration.redirect_integration"]

  rest_api_id   = aws_api_gateway_rest_api.oauth_redirect.id
  stage_name    = "dev"
  description   = "Development API to Redirect Hubspot Authorizations."
}