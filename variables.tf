variable "resume_website_bucket_arn" {
  default = aws_s3_bucket.resume_website.arn
 
}

variable "api_arn" {
  default = aws_api_gateway_rest_api.resume_website.execution_arn
 
}
variable "dynamodb_table" {
  default = aws_dynamodb_table.name
}

variable "api_gateway_rest_api" {
}