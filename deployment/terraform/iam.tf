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

resource "aws_iam_policy" "read_write_customers" {
  name        = "DynamoDBReadWriteCustomersTable"
  description = "Read to and Write from the customers table."

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

resource "aws_iam_policy" "read_write_hubspot" {
  name        = "DynamoDBReadWriteHubspotTable"
  description = "Read to and Write from the hubspot table."

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
        "dynamodb:UpdateItem",
        "dynamodb:DescribeTable"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.hubspot.arn}"
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

resource "aws_iam_policy_attachment" "attach_customers_dynamo" {
  name       = "dynamodb-customers-attachment"
  roles      = [
    aws_iam_role.lambda_download.name,
  ]
  policy_arn = aws_iam_policy.read_write_customers.arn
}

resource "aws_iam_policy_attachment" "attach_hubspot_dynamo" {
  name       = "dynamodb-hubspot-attachment"
  roles      = [
    aws_iam_role.lambda_redirect.name,
  ]
  policy_arn = aws_iam_policy.read_write_hubspot.arn
}
