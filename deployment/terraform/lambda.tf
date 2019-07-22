resource "aws_lambda_function" "download_customers" {
  filename          = "../packages/downloadCustomers/function.zip"
  source_code_hash  = filebase64sha256("../packages/downloadCustomers/function.zip")
  handler           = "main.lambda_handler"

  function_name     = local.lambda_download_customers_name
  role              = aws_iam_role.lambda_download.arn
  
  runtime           = "python3.7"
  timeout           = 10

  environment {
    variables = {
      FTP_USERNAME  = var.ftp_username
      FTP_PASSWORD  = var.ftp_password
      FTP_URL       = var.ftp_url
      LOGLEVEL      = var.log_level
    }
  }
}

resource "aws_lambda_function" "redirect_oauth" {
  filename          = "../packages/redirectOAuth/function.zip"
  source_code_hash  = filebase64sha256("../packages/redirectOAuth/function.zip")
  handler           = "main.lambda_handler"

  function_name     = local.lambda_redirect_oauth_name
  role              = aws_iam_role.lambda_redirect.arn
  
  runtime           = "python3.7"
  timeout           = 3

  environment {
    variables = {
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      REDIRECT_URI  = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_resource.confirm_resource.path}"
      LOGLEVEL      = var.log_level
    }
  }
}

resource "aws_cloudwatch_log_group" "download_customers" {
  name = "/aws/lambda/${local.lambda_download_customers_name}"
}

resource "aws_cloudwatch_log_group" "redirect_oauth" {
  name = "/aws/lambda/${local.lambda_redirect_oauth_name}"
}

resource "aws_cloudwatch_event_rule" "every_morning" {
  name                = "every-morning-at-8am"
  description         = "Triggers every day at 8am"
  schedule_expression = "cron(0 8 * * ? *)"
}

resource "aws_cloudwatch_event_target" "check_every_morning" {
  rule      = aws_cloudwatch_event_rule.every_morning.name
  target_id = "check_daisy_server"
  arn       = aws_lambda_function.download_customers.arn
}

resource "aws_lambda_permission" "allow_execution_from_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.download_customers.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_morning.arn
}

resource "aws_lambda_permission" "allow_execution_from_redirect_gateway" {
  statement_id  = "AllowExecutionFromAPIGatewayRedirect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect_oauth.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.oauth_redirect.id}/*/${aws_api_gateway_method.redirect_method.http_method}${aws_api_gateway_resource.redirect_resource.path}"
}

resource "aws_lambda_permission" "allow_execution_from_confirm_gateway" {
  statement_id  = "AllowExecutionFromAPIGatewayConfirm"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect_oauth.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.oauth_redirect.id}/*/${aws_api_gateway_method.confirm_method.http_method}${aws_api_gateway_resource.confirm_resource.path}"
}
