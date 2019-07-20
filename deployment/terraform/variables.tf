variable "region" {
  description = "The AWS region to deploy in."
  default = "eu-west-2"
}

variable "table_name" {
  description = "Name of the DynamoDB Table to use."
  default = "customers"
}

variable "ftp_username" {
  description = "Username to log into Daisy FTP Server."
}

variable "ftp_password" {
  description = "Password to log into Daisy FTP Server."
}

variable "ftp_url" {
  description = "URL at which the Daisy FTP Server is located."
  default     = "dwp.digitalwholesalesolutions.com"
}

variable "log_level" {
  description = "Level at which to log in CloudWatch."
  default     = "INFO"
}
