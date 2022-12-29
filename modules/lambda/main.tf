# Create the Lambda function
resource "aws_lambda_function" "resume_website" {
  s3_bucket     = "my-resume-website-lambda"
  s3_key        = "lambda.zip"
  function_name = "handler"
  handler       = "index.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
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

resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resume_website.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_arn}/*"
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
 "Resource": "${var.dynamodb_table.arn}",
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


