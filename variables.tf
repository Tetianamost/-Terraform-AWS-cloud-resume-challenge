variable "resume_website_bucket_arn" {
  type = string
}
variable "api_arn" {
  type = string
}
variable "dynamodb_table" {
  type = object({
    arn = string
  })
}

variable "api_gateway_rest_api" {}