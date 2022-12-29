resume_website_bucket_arn =  "my-resume-website-latest.s3-website-us-east-1.amazonaws.com"
api_arn =  aws_api_gateway_rest_api.resume_website.execution_arn
dynamodb_table = aws_dynamodb_table.name
api_gateway_rest_api = api_gateway_rest_api 