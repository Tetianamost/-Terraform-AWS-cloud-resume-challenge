variable "resume_website_bucket_arn" {
  type = string
}
variable "api_arn" {
  type = string
}
variable "dynamodb_table" {
     default = "my-resume-website-table"
}

variable "api_gateway_rest_api" {}