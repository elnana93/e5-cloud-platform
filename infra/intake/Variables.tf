variable "dynamodb_table_name" {
  description = "Name of the intake DynamoDB table"
  type        = string
  default     = "FrontPageCity_Intake"
}

variable "random_suffix" {
  description = "Unique suffix for globally unique S3 bucket naming"
  type        = string
}