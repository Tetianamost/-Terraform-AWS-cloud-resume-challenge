provider "aws" {
  region = "us-east-1"
}

module "s3-cloudfront-cert" {
  source = "./modules/s3-cloudfront-cert"
}

module "apigateway" {
  source = "./modules/apigateway"
}

module "lambda" {
  source = "./modules/lambda"
}

module "route53" {
  source = "./modules/route53"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

