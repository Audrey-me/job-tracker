terraform{
    required_providers {
       aws = {
        source = "hashicorp/aws",
        version = "~> 4.16"  
       }
    }
}

provider "aws" {
    region= "us-west-2" 
}

# create a dynamodb table
resource "aws_dynamodb_table" "resume-data-table" {
    name = "ResumeTable"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "email_used"
    attribute {
        name = "email_used"
        type = "S"
    }
    global_secondary_index {
    name               = "email_index"
    hash_key           = "email_used"
    projection_type    = "ALL"  
  }
}
# end of creating a dynamodb table

# create an s3 bucket
resource "aws_s3_bucket" "resume_pdfs" {
  bucket = "resume-pdfs-bucket"
}
# end of creating an s3 bucket

# creates a lambda function
    # this creates a role that the lambda function will assume
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Additional policy for the Lambda function to access DynamoDB table and the table for query too
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions   = ["dynamodb:*"]
    resources = [
      "arn:aws:dynamodb:*:*:table/ResumeTable",
      "arn:aws:dynamodb:*:*:table/ResumeTable/index/email_index"
    ]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Package Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "resume_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "lambda_function_name"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"  
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.10"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "ResumeTable"
      ENVIRONMENT = "production"
      S3_BUCKET_NAME = "resume-pdfs-bucket"
    }
  }
}

# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "resume_api" {
  name        = "resume-api"
  description = "API for handling resume submissions"
}

# Create the /resume resource
resource "aws_api_gateway_resource" "resume_resource" {
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "resume"
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
}

# Create the /resume/list resource
resource "aws_api_gateway_resource" "resume_list_resource" {
  parent_id   = aws_api_gateway_resource.resume_resource.id
  path_part   = "list"
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
}

# Create the /resume/person resource
resource "aws_api_gateway_resource" "resume_person_resource" {
  parent_id   = aws_api_gateway_resource.resume_resource.id
  path_part   = "person"
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
}

# POST Method for /resume
resource "aws_api_gateway_method" "resume_method_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.resume_resource.id
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
}

# Integration for POST /resume
resource "aws_api_gateway_integration" "resume_api_integration" {
  http_method             = aws_api_gateway_method.resume_method_post.http_method
  resource_id             = aws_api_gateway_resource.resume_resource.id
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.resume_lambda.invoke_arn
}

# GET Method for /resume/list
resource "aws_api_gateway_method" "resume_list_method_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.resume_list_resource.id
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
}

# Integration for GET /resume/list
resource "aws_api_gateway_integration" "resume_list_api_integration" {
  http_method             = aws_api_gateway_method.resume_list_method_get.http_method
  resource_id             = aws_api_gateway_resource.resume_list_resource.id
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.resume_lambda.invoke_arn
}

# GET Method for /resume/person
resource "aws_api_gateway_method" "resume_person_method_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.resume_person_resource.id
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id

  request_parameters = {
    "method.request.querystring.email" = true
  }
}

# Integration for GET /resume/person
resource "aws_api_gateway_integration" "resume_person_api_integration" {
  http_method             = aws_api_gateway_method.resume_person_method_get.http_method
  resource_id             = aws_api_gateway_resource.resume_person_resource.id
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.resume_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.email" = "method.request.querystring.email"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resume_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

# Deploy the API
resource "aws_api_gateway_deployment" "resume_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resume_resource.id,
      aws_api_gateway_method.resume_method_post.id,
      aws_api_gateway_integration.resume_api_integration.id,
      aws_api_gateway_resource.resume_list_resource.id,
      aws_api_gateway_method.resume_list_method_get.id,
      aws_api_gateway_integration.resume_list_api_integration.id,
      aws_api_gateway_resource.resume_person_resource.id,
      aws_api_gateway_method.resume_person_method_get.id,
      aws_api_gateway_integration.resume_person_api_integration.id,
    ]))
  }
}

# Create a stage for the API deployment
resource "aws_api_gateway_stage" "resume_api_stage" {
  deployment_id = aws_api_gateway_deployment.resume_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  stage_name    = "prod"
}


output "api_resume_endpoint" {
  value = "${aws_api_gateway_rest_api.resume_api.execution_arn}/resume"
}

output "api_resume_list_endpoint" {
  value = "${aws_api_gateway_rest_api.resume_api.execution_arn}/resume/list"
}

output "api_resume_person_endpoint" {
  value = "${aws_api_gateway_rest_api.resume_api.execution_arn}/resume/person"
}
# end of creating an api gateway resource




