resource "aws_dynamodb_table" "resume_website" {
  name           = "my-resume-website-table"
  billing_mode   = "PROVISIONED"
  write_capacity = 5
  read_capacity  = 5

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "count"
    type = "N"
  }

  hash_key  = "id"
  range_key = "count"

  global_secondary_index {
    name            = "count_index"
    hash_key        = "count"
    range_key       = "id"
    write_capacity  = 5
    read_capacity   = 5
    projection_type = "ALL"
  }

}
