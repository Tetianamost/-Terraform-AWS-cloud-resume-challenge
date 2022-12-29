variable "api_arn" {
  type = string
}
variable "dynamodb_table" {
type = object({
arn = string
})
}