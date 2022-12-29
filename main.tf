provider "aws" {
  region = "us-east-1"
}

module "s3-cloudfront-cert" {
  source = "./modules/s3-cloudfront-cert"
}

module "apigateway" {
  source = "./modules/apigateway"

  api_gateway_rest_api = aws_api_gateway_rest_api.resume_website
}

module "lambda" {
  source  = "./modules/lambda"
  api_arn = module.apigateway.api_gateway_rest_api.execution_arn
  
}


module "route53" {
  source = "./modules/route53"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

