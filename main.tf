provider "aws" {
  region = "us-east-1"
}

module "s3-cloudfront-cert" {
  source = "./modules/s3-cloudfront-cert"
}

module "apigateway" {
  source = "./apigateway"

  api_gateway_rest_api = aws_api_gateway_rest_api.resume_website
}

module "lambda" {
  source  = "./lambda"
  api_arn = module.apigateway.api_gateway_rest_api.execution_arn
  
}


module "route53" {
  source = "./modules/route53"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

