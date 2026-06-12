# API Gateway access logging for REST API stages.

locals {
  api_gateway_access_log_format = jsonencode({
    requestId          = "$context.requestId"
    extendedRequestId  = "$context.extendedRequestId"
    apiId              = "$context.apiId"
    stage              = "$context.stage"
    requestTime        = "$context.requestTime"
    requestTimeEpoch   = "$context.requestTimeEpoch"
    sourceIp           = "$context.identity.sourceIp"
    userAgent          = "$context.identity.userAgent"
    httpMethod         = "$context.httpMethod"
    resourcePath       = "$context.resourcePath"
    path               = "$context.path"
    status             = "$context.status"
    protocol           = "$context.protocol"
    responseLength     = "$context.responseLength"
    integrationStatus  = "$context.integration.status"
    integrationLatency = "$context.integration.latency"
    errorMessage       = "$context.error.message"
    wafStatus          = "$context.waf.status"
    wafLatency         = "$context.waf.latency"
    wafResponseCode    = "$context.wafResponseCode"
    webAclArn          = "$context.webaclArn"
    dynamoDBTableName   = "$context.authorizer.claims.dynamodbTableName"
    dynamoDBOperation   = "$context.authorizer.claims.dynamodbOperation"
    dynamoDBItemId      = "$context.authorizer.claims.dynamodbItemId"
    dynamoDBErrorMessage = "$context.authorizer.claims.dynamodbErrorMessage"
  })
}

resource "aws_cloudwatch_log_group" "python_api_gateway_access_logs" {
  name              = "/aws/apigateway/${var.project_name}/python-prod-access"
  retention_in_days = var.api_gateway_access_log_retention_days
}

resource "aws_cloudwatch_log_group" "node_api_gateway_access_logs" {
  name              = "/aws/apigateway/${var.project_name}/node-prod-access"
  retention_in_days = var.api_gateway_access_log_retention_days
}



# Create a Log Group for API Gateway to push logs to
resource "aws_cloudwatch_log_group" "DynamoDB_LogGroup" {
  name_prefix = "/aws/APIGW/dynamodb/${var.project_name}-access-logs"
}

# Create a Log Policy to allow Cloudwatch to Create log streams and put logs
resource "aws_cloudwatch_log_resource_policy" "DynamoDB_CloudWatchLogPolicy" {
  policy_name     = "Terraform-DynamoDB-CloudWatchLogPolicy-${data.aws_caller_identity.current.account_id}"
  
policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Id": "CWLogsPolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [ 
          "apigateway.amazonaws.com",
          "delivery.logs.amazonaws.com"
          ]
      },
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ],
      "Resource": "${aws_cloudwatch_log_group.DynamoDB_LogGroup.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_api_gateway_rest_api.PythonAPI.arn}/*"
        }
      }
    }
  ]
}
EOF
}



# Configure API Gateway to push all logs to CloudWatch Logs
resource "aws_api_gateway_method_settings" "python_api_gateway_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id
  stage_name  = aws_api_gateway_stage.PythonStage.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}



# Configure API Gateway to push all logs to CloudWatch Logs
resource "aws_api_gateway_method_settings" "node_api_gateway_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id
  stage_name  = aws_api_gateway_stage.NodeStage.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}


/*

# Create a new API Gateway stage with logging enabled
resource "aws_api_gateway_stage" "MyApiGatewayStage" {
  deployment_id = aws_api_gateway_deployment.MyApiGatewayDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  stage_name    = "v1"
  depends_on    = [aws_api_gateway_account.ApiGatewayAccountSetting]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.MyLogGroup.arn
    format          = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
  }
}
*/
