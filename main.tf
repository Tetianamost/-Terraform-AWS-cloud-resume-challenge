provider "aws" {
  region = "us-east-1"
}

module "s3-cloudfront-cert" {
  source = "./modules/s3-cloudfront-cert"
}

module "apigateway" {
  source = "./modules/apigateway"

  api_gateway_rest_api = var.api_gateway_rest_api
}

module "lambda" {
  source         = "./modules/lambda"
  api_arn        = module.apigateway.api_gateway_rest_api.execution_arn
  dynamodb_table = module.dynamodb.dynamodb_table

}


module "route53" {
  source = "./modules/route53"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

