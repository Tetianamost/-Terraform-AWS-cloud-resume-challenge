provider "aws" {
  region = "us-east-1"
}

module "s3-cloudfront-cert" {}

module "apigateway" {}

module "lambda" {}

module "route53" {}

module "dynamodb" {}

