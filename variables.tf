variable "resume_website_bucket_arn" {
  type = string
}
variable "api_arn" {
  type = string
}
variable "dynamodb_table" {
     default = "my-resume-website-table"
  type = object({
    arn = string
  })
}

variable "api_gateway_rest_api" {}