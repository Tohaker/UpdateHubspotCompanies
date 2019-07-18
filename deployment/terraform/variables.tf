variable "region" {
  description = "The AWS region to deploy in."
  default = "eu-west-2"
}

variable "table_name" {
  description = "Name of the DynamoDB Table to use."
  default = "services"
}