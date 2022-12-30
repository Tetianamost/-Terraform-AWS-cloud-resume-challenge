provider "aws" {
  region = "us-east-1"
}
resource "aws_s3_bucket" "resume_website" {
  bucket = "bythebeach.store"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

output "s3_website_endpoint" {
  value = aws_s3_bucket.resume_website.website_endpoint
}

resource "aws_cloudfront_distribution" "resume_website" {
  origin {
    domain_name = "bythebeach.store"
    origin_id   = "CustomOrigin"

    custom_origin_config {
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
    }
  }


  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.resume_website.arn
    ssl_support_method  = "sni-only"
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["resume.bythebeach.store", "bythebeach.store"]

  default_cache_behavior {
    target_origin_id       = "CustomOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    min_ttl                = 86400
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
}
resource "aws_cloudfront_origin_access_identity" "resume_website" {
  comment = "OAI for resume website"
}

resource "aws_acm_certificate" "resume_website" {
  domain_name               = "bythebeach.store"
  subject_alternative_names = ["*.bythebeach.store"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
# Create the Lambda function
resource "aws_lambda_function" "resume_website" {
  s3_bucket     = "my-resume-website-lambda"
  s3_key        = "lambda.zip"
  function_name = "handler"
  handler       = "index.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_s3_bucket_policy" "lambda_access" {
  bucket = "my-resume-website-lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaFunctionAccess",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-resume-website-lambda",
        "arn:aws:s3:::my-resume-website-lambda/*"
      ]
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "allow_s3_access" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resume_website.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.resume_website.arn
}
# Create the IAM policy
resource "aws_iam_policy" "api_gateway_lambda_policy" {
  name        = "api_gateway_lambda_policy"
  description = "Grants API Gateway permission to invoke Lambda functions"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": "lambda:*",
          "Resource": "*"
      }
  ]
}
EOF
}

# Create the IAM role for API Gateway
resource "aws_iam_role" "api_gateway_service_role" {
  name = "api_gateway_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach the policy to the IAM role
resource "aws_iam_policy_attachment" "api_gateway_lambda_policy_attachment" {
  name       = "api_gateway_lambda_policy_attachment"
  policy_arn = aws_iam_policy.api_gateway_lambda_policy.arn
  roles      = [aws_iam_role.api_gateway_service_role.name]
}


resource "aws_iam_role" "lambda_role" {
  name               = "my-resume-website-lambda-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Grant the Lambda function permission to execute
resource "aws_lambda_permission" "allow_execute" {
  statement_id  = "AllowExecution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resume_website.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_website.execution_arn}/*"
}


resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name   = "my-resume-website-lambda-dynamodb-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "${aws_dynamodb_table.resume_website.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_api_gateway_rest_api" "resume_website" {
  name = "my-resume-website-api"
  body = jsonencode({
    openapi = "3.0.1"
    info = {

      version = "1.0"
    }
    paths = {
      resume = {
        any = {
          x-amazon-apigateway-integration = {
            httpMethod           = "ANY"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.resume_website.invoke_arn
          }
        }
      }
    }
  })
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "resume_website" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  parent_id   = aws_api_gateway_rest_api.resume_website.root_resource_id
  path_part   = "resume"
}
resource "aws_api_gateway_method" "resume_website_get" {
  rest_api_id      = aws_api_gateway_rest_api.resume_website.id
  resource_id      = aws_api_gateway_resource.resume_website.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false


}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_website.id
  resource_id             = aws_api_gateway_resource.resume_website.id
  http_method             = aws_api_gateway_method.resume_website_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.resume_website.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}
# Set up a method response for the method
resource "aws_api_gateway_method_response" "resume_website_get" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = aws_api_gateway_method.resume_website_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


# Set up an integration response for the integration
resource "aws_api_gateway_integration_response" "lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = aws_api_gateway_method.resume_website_get.http_method
  status_code = aws_api_gateway_method_response.resume_website_get.status_code
}
resource "aws_api_gateway_method" "resume_website_options" {
  rest_api_id   = aws_api_gateway_rest_api.resume_website.id
  resource_id   = aws_api_gateway_resource.resume_website.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "lambda_integration_options" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = aws_api_gateway_method.resume_website_options.http_method
  type        = "AWS_PROXY"

  integration_http_method = "POST"
  uri                     = aws_lambda_function.resume_website.invoke_arn

}
resource "aws_api_gateway_method_response" "resume_website_options" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = aws_api_gateway_method.resume_website_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}



#Set up a deployment for the API Gateway
resource "aws_api_gateway_deployment" "resume_website" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  stage_name  = "dev"
  depends_on = [
    aws_api_gateway_method.resume_website_get,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.resume_website_get,
    aws_api_gateway_integration_response.lambda_integration_response
  ]
}

#Create an output with the API Gateway endpoint URL

output "api_endpoint_url" {
  value = aws_api_gateway_deployment.resume_website.invoke_url
}




resource "aws_route53_zone" "resume_website" {
  name = "bythebeach.store"
}

resource "aws_route53_record" "resume_website" {
  zone_id = aws_route53_zone.resume_website.zone_id
  name    = "resume.bythebeach.store"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.resume_website.domain_name
    zone_id                = aws_cloudfront_distribution.resume_website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_dynamodb_table" "resume_website" {
  name           = "my-resume-website-table"
  billing_mode   = "PROVISIONED"
  write_capacity = 5
  read_capacity  = 5

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  attribute {
    name = "visit_count"
    type = "N"
  }

  hash_key  = "pk"
  range_key = "sk"

  global_secondary_index {
    name            = "visit_count_index"
    hash_key        = "visit_count"
    range_key       = "sk"
    projection_type = "ALL"
    write_capacity  = 5
    read_capacity   = 5
  }
}
