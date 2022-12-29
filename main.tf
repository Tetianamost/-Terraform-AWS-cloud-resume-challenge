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
  api_arn        = module.apigateway.api_gateway_rest_api.execution_arn
  dynamodb_table = module.dynamodb.dynamodb_table

}

module "dynamodb" {
  source = "./modules/dynamodb"
}

