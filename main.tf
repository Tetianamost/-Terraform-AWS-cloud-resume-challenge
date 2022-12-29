provider "aws" {
  region = "us-east-1"
}

module "content-delivery" {
  source = "./modules/content-delivery"
}

module "apigateway" {
  source = "./modules/apigateway"
  
}

module "lambda" {
  source         = "./modules/lambda"
  api_arn        = var.api_gateway_rest_api.execution_arn
  dynamodb_table = var.dynamodb_table.arn

}

module "dynamodb" {
  source = "./modules/dynamodb"
}

