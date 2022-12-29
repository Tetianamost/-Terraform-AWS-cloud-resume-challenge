resource "aws_api_gateway_rest_api" "resume_website" {
  name = "my-resume-website-api"
}

resource "aws_api_gateway_resource" "resume_website" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  parent_id   = aws_api_gateway_rest_api.resume_website.root_resource_id
  path_part   = "resume"
}
resource "aws_api_gateway_integration" "lambda_integration_get" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  depends_on  = [aws_lambda_permission.apigw_invoke_lambda]
  http_method = "GET"
  type        = "AWS_PROXY"
  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }
  uri = aws_lambda_function.resume_website.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = "POST"
  type        = "AWS_PROXY"
  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }
  uri = aws_lambda_function.resume_website.invoke_arn
}

resource "aws_api_gateway_method" "resume_website_get" {
  rest_api_id   = aws_api_gateway_rest_api.resume_website.id
  resource_id   = aws_api_gateway_resource.resume_website.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "resume_website_post" {
  rest_api_id   = aws_api_gateway_rest_api.resume_website.id
  resource_id   = aws_api_gateway_resource.resume_website.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "resume_website_get_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = aws_api_gateway_method.resume_website_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_method_response" "resume_website_options" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  resource_id = aws_api_gateway_resource.resume_website.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"  = true,
    "method.response.header.Access-Control-Allow-Methods"  = true,
    "method.response.header.Access-Control-Allow-Origin"   = true,
    "method.response.header.Access-Control-Expose-Headers" = true
  }
}
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume_website.id
  stage_name  = "prod"
}
