resource "aws_iam_role" "lambda_download" {
  name                = "lambda_downloadCustomers"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AssumeLambdaRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_redirect" {
  name                = "lambda_oauthRedirect"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AssumeLambdaRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "read_write_services" {
  name        = "DynamoDBReadWriteServicesTable"
  description = "Read to and Write from the specified table."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.customers.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "CloudWatchLambdaLogging"
  description = "Create and Write to all CloudWatch Logs."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach_logging" {
  name       = "lambda-attachment"
  roles      = [
    aws_iam_role.lambda_download.name,
    aws_iam_role.lambda_redirect.name
  ]
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy_attachment" "attach_dyanmo" {
  name       = "dynamodb-attachment"
  roles      = [
    aws_iam_role.lambda_download.name
  ]
  policy_arn = aws_iam_policy.read_write_services.arn
}
