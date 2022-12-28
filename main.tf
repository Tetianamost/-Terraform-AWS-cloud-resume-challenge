provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "resume_website" {
  bucket = "my-resume-website-latest"
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
    domain_name = "www.example.com"
    origin_id   = "CustomOrigin"

   custom_origin_config {
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port             = 80
      https_port            = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
    }
  }


  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.resume_website.arn}"
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
    target_origin_id = "CustomOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "POST", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "POST", "HEAD", "OPTIONS"]
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
  domain_name       = "bythebeach.store"
  subject_alternative_names = ["*.bythebeach.store"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_rest_api" "resume_website" {
  name = "my-resume-website-api"
}

resource "aws_api_gateway_resource" "resume_website" {
  rest_api_id = "${aws_api_gateway_rest_api.resume_website.id}"
  parent_id   = "${aws_api_gateway_rest_api.resume_website.root_resource_id}"
  path_part   = "resume"
}
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id   = "${aws_api_gateway_rest_api.resume_website.id}"
  resource_id   = "${aws_api_gateway_resource.resume_website.id}"
  http_method   = "${aws_api_gateway_method.resume_website_get.http_method}"
  type          = "AWS_PROXY"
  uri           = "${aws_lambda_function.resume_website.invoke_arn}"
}
resource "aws_api_gateway_method" "resume_website_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.resume_website.id}"
  resource_id   = "${aws_api_gateway_resource.resume_website.id}"
  http_method   = "GET"
  authorization = "NONE"

  integration_id = "${aws_api_gateway_integration.lambda_integration.id}"
}
resource "aws_api_gateway_method" "resume_website_post" {
  rest_api_id   = "${aws_api_gateway_rest_api.resume_website.id}"
  resource_id   = "${aws_api_gateway_resource.resume_website.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "resume_website_post" {
  rest_api_id             = "${aws_api_gateway_rest_api.resume_website.id}"
  resource_id             = "${aws_api_gateway_resource.resume_website.id}"
  http_method             = "${aws_api_gateway_method.resume_website_post.http_method}"
  type                     = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "${aws_lambda_function.resume_website.invoke_arn}"
  request_templates = {
    "application/json" = "$input.json('$')"
  }
}


resource "aws_api_gateway_method_response" "resume_website_get_response" {
rest_api_id = "${aws_api_gateway_rest_api.resume_website.id}"
resource_id = "${aws_api_gateway_resource.resume_website.id}"
http_method = "${aws_api_gateway_method.resume_website_get.http_method}"
status_code = "200"

response_parameters = {
"method.response.header.Access-Control-Allow-Origin" = true
}
}


resource "aws_api_gateway_method_response" "resume_website_options" {
  rest_api_id = "${aws_api_gateway_rest_api.resume_website.id}"
  resource_id = "${aws_api_gateway_resource.resume_website.id}"
  http_method = "OPTIONS"
  status_code = "200"

    response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Expose-Headers" = true
  }
}


# Create the Lambda function
resource "aws_lambda_function" "resume_website" {
  s3_bucket     = "my-resume-website-lambda"
  s3_key        = "lambda.zip"
  function_name = "my-resume-website-lambda"
  handler       = "index.handler"
  runtime       = "python3.8"
  role          = "${aws_iam_role.lambda_role.arn}"
 }
 

resource "aws_iam_role" "lambda_role" {
  name = "my-resume-website-lambda-role"
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
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_dynamodb_policy.arn}"
}


resource "aws_route53_zone" "resume_website" {
  name = "bythebeach.store"
}

resource "aws_route53_record" "resume_website" {
  zone_id = "${aws_route53_zone.resume_website.zone_id}"
  name    = "resume.bythebeach.store"
  type    = "A"
  alias {
    name                   = "${aws_cloudfront_distribution.resume_website.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.resume_website.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_dynamodb_table" "resume_website" {
  name           = "my-resume-website-table"
  billing_mode   = "PROVISIONED"
   write_capacity  = 5
    read_capacity   = 5

  attribute {
    name = "id"
    type = "S"
  }
    attribute {
    name = "name"
    type = "S"
  }
   hash_key = "id"
   range_key = "name"

  global_secondary_index {
    name            = "name_index"
    hash_key        = "name"
    range_key       = "id"
    write_capacity  = 5
    read_capacity   = 5
    projection_type = "ALL"
  }

}


