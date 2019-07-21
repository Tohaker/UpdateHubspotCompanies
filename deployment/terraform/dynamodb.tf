resource "aws_dynamodb_table" "customers" {
  name           = var.customer_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "hupspot" {
  name           = var.hubspot_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "access_token"

  attribute {
    name = "access_token"
    type = "S"
  }
}
