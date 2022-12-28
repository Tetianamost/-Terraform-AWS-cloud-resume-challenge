
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "resume_website" {
  bucket = "my-resume-website"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}


resource "aws_cloudfront_distribution" "resume_website" {
  origin {
    domain_name = aws_s3_bucket.resume_website.website_domain
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.resume_website.cloudfront_access_identity_path}"
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

  default_cache_behavior {
    target_origin_id = "S3Origin"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

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
}

resource "aws_api_gateway_rest_api" "resume_website" {
  name = "my-resume-website-api"
}

resource "aws_api_gateway_resource" "resume_website" {
  rest_api_id = "${aws_api_gateway_rest_api.resume_website.id}"
  parent_id   = "${aws_api_gateway_rest_api.resume_website.root_resource_id}"
  path_part   = "resume"
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

  global_secondary_index {
    name            = "name_index"
    hash_key        = "name"
    range_key       = "id"
    write_capacity  = 5
    read_capacity   = 5
    projection_type = "ALL"
  }

}


