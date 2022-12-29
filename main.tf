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
 
 

}

module "dynamodb" {
  source = "./modules/dynamodb"
}

