variable "resume_website_bucket_arn" {
  description = "The ARN of the S3 bucket for the resume website"
  default = "Hi!"
  type        = string
}

variable "api_arn" {
    default = "Hi"
}
variable "dynamodb_table" {
    default = "Hi"
}

variable "api_gateway_rest_api" {
    default = "Hi"
}