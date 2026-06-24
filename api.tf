/********************
RBAC Flow:
1. User authenticates with Cognito.
2. Cognito issues an access token with scopes like rbac-api/admin or rbac-api/user.
3. API Gateway Cognito authorizer validates the token.
4. API Gateway checks authorization_scopes.
5. Only then does Lambda run.
6. Lambda optionally checks cognito:groups for Layer 2 defense/application logic.
**********************/
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api


# Authorizer method:
# Require a Cognito token from the Authorization header.
# Trust this Cognito user pool.
resource "aws_api_gateway_authorizer" "python_cognito" {
  name        = "python-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id

  type = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.cognito_rbac_pool.arn
  ]

  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_authorizer" "node_cognito" {
  name        = "node-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id

  type = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.cognito_rbac_pool.arn
  ]

  identity_source = "method.request.header.Authorization"
}

# Python API Gateway
resource "aws_api_gateway_rest_api" "PythonAPI" {
  name        = "PythonAPI"
  description = "This is the Python API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


# API Lambda permissions
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/lambda_permission

resource "aws_lambda_permission" "python_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGatewayPython"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.PythonAPI.execution_arn}/*/*"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource
resource "aws_api_gateway_resource" "PythonResource" {
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id
  parent_id   = aws_api_gateway_rest_api.PythonAPI.root_resource_id
  path_part   = "PythonResource"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method
resource "aws_api_gateway_method" "PythonMethod" {
  rest_api_id          = aws_api_gateway_rest_api.PythonAPI.id
  resource_id          = aws_api_gateway_resource.PythonResource.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.python_cognito.id
  authorization_scopes = ["${aws_cognito_resource_server.rbac_api_resource_server.identifier}/admin"]
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration
resource "aws_api_gateway_integration" "PythonIntegration" {
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id
  resource_id = aws_api_gateway_resource.PythonResource.id
  http_method = aws_api_gateway_method.PythonMethod.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.python_lambda.invoke_arn

  timeout_milliseconds = 29000
}


# https://registry.terraform.io/providers/hashicorp/awS/latest/docs/resources/api_gateway_deployment
resource "aws_api_gateway_deployment" "PythonDeployment" {
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.PythonResource.id,
      aws_api_gateway_method.PythonMethod.id,
      aws_api_gateway_integration.PythonIntegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage
# Staging - Python
resource "aws_api_gateway_stage" "PythonStage" {
  deployment_id = aws_api_gateway_deployment.PythonDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.PythonAPI.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.python_api_gateway_access_logs.arn
    format          = local.api_gateway_access_log_format
  }

  depends_on = [aws_api_gateway_account.api_gateway_cloudwatch]
}

# API Gateway Throttling - Python
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings
resource "aws_api_gateway_method_settings" "PythonStageThrottle" {
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id
  stage_name  = aws_api_gateway_stage.PythonStage.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "INFO"
    metrics_enabled        = true
    data_trace_enabled     = var.api_data_trace_enabled
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }
}


#############################################################################################################################################

# Node API Gateway
resource "aws_api_gateway_rest_api" "NodeAPI" {
  name        = "NodeAPI"
  description = "This is the Node API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


# API Lambda permissions
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/lambda_permission

resource "aws_lambda_permission" "node_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGatewayNode"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.NodeAPI.execution_arn}/*/*"
}


resource "aws_api_gateway_resource" "NodeResource" {
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id
  parent_id   = aws_api_gateway_rest_api.NodeAPI.root_resource_id
  path_part   = "NodeResource"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method
resource "aws_api_gateway_method" "NodeMethod" {
  rest_api_id          = aws_api_gateway_rest_api.NodeAPI.id
  resource_id          = aws_api_gateway_resource.NodeResource.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.node_cognito.id
  authorization_scopes = ["rbac-api/admin"]
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration
resource "aws_api_gateway_integration" "NodeIntegration" {
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id
  resource_id = aws_api_gateway_resource.NodeResource.id
  http_method = aws_api_gateway_method.NodeMethod.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.node_lambda.invoke_arn

  timeout_milliseconds = 29000
}


# https://registry.terraform.io/providers/hashicorp/awS/latest/docs/resources/api_gateway_deployment
resource "aws_api_gateway_deployment" "NodeDeployment" {
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.NodeResource.id,
      aws_api_gateway_method.NodeMethod.id,
      aws_api_gateway_integration.NodeIntegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage
# Staging - Node
resource "aws_api_gateway_stage" "NodeStage" {
  deployment_id = aws_api_gateway_deployment.NodeDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.NodeAPI.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.node_api_gateway_access_logs.arn
    format          = local.api_gateway_access_log_format
  }

  depends_on = [aws_api_gateway_account.api_gateway_cloudwatch]
}

# API Gateway Throttling - Node
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings
resource "aws_api_gateway_method_settings" "NodeStageThrottle" {
  rest_api_id = aws_api_gateway_rest_api.NodeAPI.id
  stage_name  = aws_api_gateway_stage.NodeStage.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "INFO"
    metrics_enabled        = true
    data_trace_enabled     = var.api_data_trace_enabled
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }
}


# API Gateway Roles

# API Gatway - CloudWatch Logs Role
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.project_name}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway_cloudwatch" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch_logs]
}


# API Gateway DynamoDB Role
resource "aws_iam_role" "api_gateway_dynamodb_role" {
  name = "${var.project_name}-api-gateway-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_dynamodb_role_attachment" {
  role       = aws_iam_role.api_gateway_dynamodb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


# DynamoDB Put Role for API Gateway
resource "aws_iam_policy" "api_gateway_dynamodb_put_query_policy" {
  name        = "${var.project_name}-api-gateway-dynamodb-policy"
  description = "Policy for API Gateway to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:Query"
      ]
      Resource = ["${aws_dynamodb_table.dynamoDb_token_tracking.arn}",
      "${aws_dynamodb_table.dynamoDb_token_tracking.arn}/index/*"]
    }]
  })

}


resource "aws_iam_role_policy_attachment" "api_gateway_dynamodb_attachment" {
  role       = aws_iam_role.api_gateway_dynamodb_role.name
  policy_arn = aws_iam_policy.api_gateway_dynamodb_put_query_policy.arn
}



#Create a new Python API Gateway rest api with DynamoDB Integration that requires an API Key for security
resource "aws_api_gateway_rest_api" "python_agw_RestApi" {
  name = "APIGW DynamoDB Serverless Pattern Demo"
  body = jsonencode({
    "swagger" : "2.0",
    "info" : {
      "version" : "2022-03-21T11:36:12Z",
      "title" : "APIGW DynamoDB Serverless Pattern Demo"
    },
    "basePath" : "/v1",
    "schemes" : ["https"],
    "paths" : {
      "/tokens" : {
        "post" : {
          "consumes" : ["application/json"],
          "produces" : ["application/json"],
          "responses" : {
            "200" : {
              "description" : "200 response"
            }
          },
          "security" : [{
            "DynamoDb_PythonAPIKey" : []
          }],
          "x-amazon-apigateway-integration" : {
            "type" : "aws",
            "credentials" : "${aws_iam_role.api_gateway_dynamodb_role.arn}",
            "httpMethod" : "POST",
            "uri" : "arn:aws:apigateway:${data.aws_region.current.id}:dynamodb:action/PutItem",
            "responses" : {
              "default" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : "{}"
                }
              }
            },
            "requestTemplates" : {
              "application/json" : "{\"TableName\":\"token-tracking\",\"Item\":{\"id\":{\"S\":\"$context.requestId\"},\"TokenType\":{\"S\":\"$input.path('$.TokenType')\"},\"TokenName\":{\"S\":\"$input.path('$.TokenName')\"},\"TokenValue\":{\"N\":\"$input.path('$.TokenValue')\"}}}"
            },
            "passthroughBehavior" : "when_no_templates"
          }
        }
      },
      "/tokens/{token_hash}" : {
        "get" : {
          "consumes" : ["application/json"],
          "produces" : ["application/json"],
          "parameters" : [{
            "name" : "token_hash",
            "in" : "path",
            "required" : true,
            "type" : "string"
          }],
          "responses" : {
            "200" : {
              "description" : "200 response"
            }
          },
          "security" : [{
            "DynamoDb_PythonAPIKey" : []
          }],
          "x-amazon-apigateway-integration" : {
            "type" : "aws",
            "credentials" : "${aws_iam_role.api_gateway_dynamodb_role.arn}",
            "httpMethod" : "POST",
            "uri" : "arn:aws:apigateway:${data.aws_region.current.id}:dynamodb:action/Query",
            "responses" : {
              "default" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : "#set($inputRoot = $input.path('$'))\n{\n\t\"tokens\": [\n\t\t#foreach($field in $inputRoot.Items) {\n\t\t\t\"token_id\": \"$field.token_id.S\",\n\t\t\t\"token_hash\": \"$field.token_hash.S\",\n\t\t\t\"username\": \"$field.username.S\",\n\t\t\t\"status\": \"$field.status.S\",\n\t\t\t\"expires_at\": \"$field.expires_at.N\"\n\t\t}#if($foreach.hasNext),#end\n\t\t#end\n\t]\n}"
                }
              }
            },
            "requestParameters" : {
              "integration.request.path.token_hash" : "method.request.path.token_hash"
            },
            "requestTemplates" : {
              "application/json" : "{\"TableName\":\"token-tracking\",\"IndexName\":\"token-hash-index\",\"KeyConditionExpression\":\"token_hash=:v1\",\"ExpressionAttributeValues\":{\":v1\":{\"S\":\"$util.urlDecode($input.params('token_hash'))\"}}}"
            },
            "passthroughBehavior" : "when_no_templates"
          }
        }
      }
    },
    "securityDefinitions" : {
      "DynamoDb_PythonAPIKey" : {
        "type" : "apiKey",
        "name" : "x-api-key",
        "in" : "header"
      }
    }
  })
}


# Create an API Gateway Key
resource "aws_api_gateway_api_key" "DynamoDb_PythonAPIKey" {
  name = "apigw-dynamodb-python-api-key"
}


#Create a new Python API Gateway rest api with DynamoDB Integration that requires an API Key for security
resource "aws_api_gateway_rest_api" "node_agw_rest_api" {
  name = "APIGW DynamoDB Serverless Pattern Demo"
  body = jsonencode({
    "swagger" : "2.0",
    "info" : {
      "version" : "2022-03-21T11:36:12Z",
      "title" : "APIGW DynamoDB Serverless Pattern Demo"
    },
    "basePath" : "/v1",
    "schemes" : ["https"],
    "paths" : {
      "/tokens" : {
        "post" : {
          "consumes" : ["application/json"],
          "produces" : ["application/json"],
          "responses" : {
            "200" : {
              "description" : "200 response"
            }
          },
          "security" : [{
            "DynamoDb_NodeAPIKey" : []
          }],
          "x-amazon-apigateway-integration" : {
            "type" : "aws",
            "credentials" : "${aws_iam_role.api_gateway_dynamodb_role.arn}",
            "httpMethod" : "POST",
            "uri" : "arn:aws:apigateway:${data.aws_region.current.id}:dynamodb:action/PutItem",
            "responses" : {
              "default" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : "{}"
                }
              }
            },
            "requestTemplates" : {
              "application/json" : "{\"TableName\":\"token-tracking\",\"Item\":{\"id\":{\"S\":\"$context.requestId\"},\"TokenType\":{\"S\":\"$input.path('$.TokenType')\"},\"TokenName\":{\"S\":\"$input.path('$.TokenName')\"},\"TokenValue\":{\"N\":\"$input.path('$.TokenValue')\"}}}"
            },
            "passthroughBehavior" : "when_no_templates"
          }
        }
      },
      "/tokens/{token_hash}" : {
        "get" : {
          "consumes" : ["application/json"],
          "produces" : ["application/json"],
          "parameters" : [{
            "name" : "token_hash",
            "in" : "path",
            "required" : true,
            "type" : "string"
          }],
          "responses" : {
            "200" : {
              "description" : "200 response"
            }
          },
          "security" : [{
            "DynamoDb_NodeAPIKey" : []
          }],
          "x-amazon-apigateway-integration" : {
            "type" : "aws",
            "credentials" : "${aws_iam_role.api_gateway_dynamodb_role.arn}",
            "httpMethod" : "POST",
            "uri" : "arn:aws:apigateway:${data.aws_region.current.id}:dynamodb:action/Query",
            "responses" : {
              "default" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : "#set($inputRoot = $input.path('$'))\n{\n\t\"tokens\": [\n\t\t#foreach($field in $inputRoot.Items) {\n\t\t\t\"token_id\": \"$field.token_id.S\",\n\t\t\t\"token_hash\": \"$field.token_hash.S\",\n\t\t\t\"username\": \"$field.username.S\",\n\t\t\t\"status\": \"$field.status.S\",\n\t\t\t\"expires_at\": \"$field.expires_at.N\"\n\t\t}#if($foreach.hasNext),#end\n\t\t#end\n\t]\n}"
                }
              }
            },
            "requestParameters" : {
              "integration.request.path.token_hash" : "method.request.path.token_hash"
            },
            "requestTemplates" : {
              "application/json" : "{\"TableName\":\"token-tracking\",\"IndexName\":\"token-hash-index\",\"KeyConditionExpression\":\"token_hash=:v1\",\"ExpressionAttributeValues\":{\":v1\":{\"S\":\"$util.urlDecode($input.params('token_hash'))\"}}}"
            },
            "passthroughBehavior" : "when_no_templates"
          }
        }
      }
    },
    "securityDefinitions" : {
      "DynamoDb_NodeAPIKey" : {
        "type" : "apiKey",
        "name" : "x-api-key",
        "in" : "header"
      }
    }
  })
}


# Create an API Gateway Key
resource "aws_api_gateway_api_key" "DynamoDb_NodeAPIKey" {
  name = "apigw-dynamodb-node-api-key"
}





# Create an API Gateway Usage Plan key and associate it to the previously created API Key

resource "aws_api_gateway_usage_plan" "DynamoDb_apigw_python_usage_plan" {
  name = "apigw-dynamodb-node-usage-plan"
}

resource "aws_api_gateway_usage_plan_key" "DynamoDb_apigw_python_usage_key" {
  key_id        = aws_api_gateway_api_key.DynamoDb_NodeAPIKey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.DynamoDb_apigw_python_usage_plan.id
}

# Display APIGW invocation URL 
output "APIGW-URL-PYTHON" {
  value       = "${aws_api_gateway_stage.PythonStage.invoke_url}/tokens"
  description = "The DynamoDB API Gateway Invocation URL"
}


resource "aws_api_gateway_usage_plan" "DynamoDb_apigw_node_usage_plan" {
  name = "apigw-dynamodb-node-usage-plan"
}

resource "aws_api_gateway_usage_plan_key" "DynamoDb_apigw_node_usage_key" {
  key_id        = aws_api_gateway_api_key.DynamoDb_NodeAPIKey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.DynamoDb_apigw_node_usage_plan.id
}

# Display APIGW invocation URL 
output "APIGW-URL-NODE" {
  value       = "${aws_api_gateway_stage.NodeStage.invoke_url}/tokens"
  description = "The DynamoDB API Gateway Invocation URL"
}






# Display the APIGW Key to use for testing
output "APIGW-PYTHON-KEY" {
  value       = aws_api_gateway_api_key.DynamoDb_PythonAPIKey.id
  description = "The DynamoDB APIGW Key to use for testing"
}

output "APIGW-NODE-KEY" {
  value       = aws_api_gateway_api_key.DynamoDb_NodeAPIKey.id
  description = "The DynamoDB APIGW Key to use for testing"
}



/*
# Create a new API Gateway deployment for the created rest api
resource "aws_api_gateway_deployment" "MyApiGatewayDeployment" {
  rest_api_id = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
}
*/

