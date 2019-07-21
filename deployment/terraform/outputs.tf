output "redirect_url" {
  value = aws_api_gateway_deployment.redirect_deployment.invoke_url
}
