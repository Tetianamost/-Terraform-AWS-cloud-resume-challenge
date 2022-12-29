variable "resume_website_bucket_arn" {
  description = "The ARN of the S3 bucket for the resume website"
  type        = string
}

variable "api_arn" {}
variable "dynamodb_table" {}

variable "api_gateway_rest_api" {}