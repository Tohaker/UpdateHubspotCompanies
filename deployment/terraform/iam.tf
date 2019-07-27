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

resource "aws_iam_role" "lambda_update" {
  name                = "lambda_updateHubspot"
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

resource "aws_iam_role" "lambda_match" {
  name                = "lambda_matchCustomers"
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
        "dynamodb:DescribeTable",
        "dynamodb:DeleteItem"
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

resource "aws_iam_policy" "read_streams_customers" {
  name        = "DynamoDBReadCustomersStreams"
  description = "Reads from the Customers Table Streams."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
      ],
      "Resource": "${aws_dynamodb_table.customers.stream_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "publish_sns" {
  name        = "PublishToSNS"
  description = "Publishes messages to SNS."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "sns:Publish"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "invoke_lambda" {
  name        = "InvokeLambdaFunction"
  description = "Allows invokation of another Lambda Function."

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach_logging" {
  name       = "lambda-attachment"
  roles      = [
    aws_iam_role.lambda_download.name,
    aws_iam_role.lambda_redirect.name,
    aws_iam_role.lambda_update.name,
    aws_iam_role.lambda_match.name
  ]
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy_attachment" "attach_customers_dynamo" {
  name       = "dynamodb-customers-attachment"
  roles      = [
    aws_iam_role.lambda_match.name,
  ]
  policy_arn = aws_iam_policy.read_write_customers.arn
}

resource "aws_iam_policy_attachment" "attach_hubspot_dynamo" {
  name       = "dynamodb-hubspot-attachment"
  roles      = [
    aws_iam_role.lambda_redirect.name,
    aws_iam_role.lambda_match.name,
    aws_iam_role.lambda_update.name
  ]
  policy_arn = aws_iam_policy.read_write_hubspot.arn
}

resource "aws_iam_policy_attachment" "attach_customers_streams" {
  name       = "dynamodb-customers-streams-attachment"
  roles      = [
    aws_iam_role.lambda_update.name,
  ]
  policy_arn = aws_iam_policy.read_streams_customers.arn
}

resource "aws_iam_policy_attachment" "attach_sns" {
  name       = "sns-attachment"
  roles      = [
    aws_iam_role.lambda_update.name,
  ]
  policy_arn = aws_iam_policy.publish_sns.arn
}

resource "aws_iam_policy_attachment" "attach_lambda" {
  name       = "lambda-attachment"
  roles      = [
    aws_iam_role.lambda_download.name
  ]
  policy_arn =  aws_iam_policy.invoke_lambda.arn
}

