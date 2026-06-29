# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

# IAM role for Lambda execution

# Calls AWS IAM policy document for Lambda execution role
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


# Lambda policy attachment to allow Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda_bedrock_invoke" {
  name = "lambda-bedrock-invoke"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockInvokeModel"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_token_lifecycle" {
  name = "lambda-token-lifecycle"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageTokenTracking"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.dynamoDb_token_tracking.arn,
          "${aws_dynamodb_table.dynamoDb_token_tracking.arn}/index/*",
          aws_dynamodb_table.dynamoDb_token_revocation.arn
        ]
      }
    ]
  })
}

# Lambda Functions
# Package the Lambda function code - a new Provide (run init when adding)
# The `archive_file` data source is used to create a ZIP archive of the Lambda function code.
# The Lambda function handler is the method in your function code that processes events

# Node.js Lambda function
# https://registry.terraform.io/providers/hashicorp/archive/2.2.0/docs/data-sources/archive_file
data "archive_file" "node_lambda" {
  type        = "zip"
  source_file = "./src/node_lambda.js"
  output_path = "./lambda/node_lambda.zip"
}


# https://docs.aws.amazon.com/lambda/latest/dg/nodejs-handler.html
resource "aws_lambda_function" "node_lambda" {
  filename      = data.archive_file.node_lambda.output_path
  function_name = "node_lambda_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "node_lambda.handler"
  code_sha256   = data.archive_file.node_lambda.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
    }
  }

  /*
  environment {
    variables = {
      ENVIRONMENT = "development"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "development"
    Application = aws_lambda_function.node_lambda.function_name
  }
    */
}



# Python Lambda function

data "archive_file" "python_lambda" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./lambda/python_lambda.zip"
}


# https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
resource "aws_lambda_function" "python_lambda" {
  filename      = data.archive_file.python_lambda.output_path
  function_name = "python_lambda_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "python_lambda.lambda_handler"
  code_sha256   = data.archive_file.python_lambda.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
    }
  }

  /*
  environment {
    variables = {
      ENVIRONMENT = "development"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "development"
    Application = aws_lambda_function.python_lambda.function_name
  }
*/
}

# Get Token Lambda function - handles user authentication and token issuance, with tracking in DynamoDB for monitoring and security purposes. This function can be used to generate tokens for testing or as part of a larger authentication flow.
data "archive_file" "get_token" {
  type        = "zip"
  source_file = "./src/easier_get_token.py"
  output_path = "./lambda/get_token.zip"
}

resource "aws_lambda_function" "get_token" {
  filename      = data.archive_file.get_token.output_path
  function_name = "get_token_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "easier_get_token.lambda_handler"
  code_sha256   = data.archive_file.get_token.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
    }
  }
}


# RBAC
data "archive_file" "python_rbac" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./lambda/python_rbac.zip"
}

resource "aws_lambda_function" "python_rbac" {
  filename      = data.archive_file.python_rbac.output_path
  function_name = "python_rbac_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "python_rbac.lambda_handler"
  code_sha256   = data.archive_file.python_rbac.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
    }
  }
}

/*
# RBAC function for Bedrock contract testing - can be invoked by EventBridge Scheduler or other triggers to immediately check RBAC permissions based on certain conditions or events.
data "archive_file" "immediate_rbac_check_66" {
  type        = "zip"
  source_file = "./src/immediate_rbac_check_66.py"
  output_path = "./lambda/immediate_rbac_check_66.zip"
}

resource "aws_lambda_function" "immediate_rbac_check_66" {
  filename      = data.archive_file.immediate_rbac_check_66.output_path
  function_name = "immediate_rbac_check_66_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "immediate_rbac_check_66.lambda_handler"
  code_sha256   = data.archive_file.immediate_rbac_check_66.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      RBAC_TABLE_NAME = aws_dynamodb_table.dynamoDb_token_tracking.name
    }
  }
}
*/
/*
  environment {
    variables = {
      ENVIRONMENT = "development"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "development"
    Application = aws_lambda_function.immediate_rbac_check_66.function_name
  }
  */


data "archive_file" "verify_groups" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./lambda/verify_groups.zip"
}


# Verify Cognito User Groups Lambda function - can be invoked by EventBridge Scheduler or other triggers to check user group memberships in Cognito based on certain conditions or events.
resource "aws_lambda_function" "verify_groups" {
  filename      = data.archive_file.verify_groups.output_path
  function_name = "verify_groups_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "verify_groups.lambda_handler"
  code_sha256   = data.archive_file.verify_groups.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id != "" ? var.cognito_user_pool_id : aws_cognito_user_pool.cognito_rbac_pool.id
    }
  }
}



# Update Token
data "archive_file" "update_token" {
  type        = "zip"
  source_file = "./src/update_token.py"
  output_path = "./lambda/update_token.zip"
}

resource "aws_lambda_function" "update_token" {
  filename      = data.archive_file.update_token.output_path
  function_name = "update_token_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "update_token.lambda_handler"
  code_sha256   = data.archive_file.update_token.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.dynamoDb_token_tracking.name
      REVOCATION_TABLE     = aws_dynamodb_table.dynamoDb_token_revocation.name
    }
  }
}

# Retrieve extra tokens to use for API calls - check for unused tokens
data "archive_file" "unused_token_detector" {
  type        = "zip"
  source_file = "./src/unused_token_detector.py"
  output_path = "./lambda/unused_token_detector.zip"
}
resource "aws_lambda_function" "unused_token_detector" {
  filename      = data.archive_file.unused_token_detector.output_path
  function_name = "unused_token_detector_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "unused_token_detector.lambda_handler"
  code_sha256   = data.archive_file.unused_token_detector.output_base64sha256

  runtime = "python3.9"
  timeout = 180

  environment {
    variables = {
      TOKEN_TRACKING_TABLE           = aws_dynamodb_table.dynamoDb_token_tracking.name
      UNUSED_TOKEN_ALERT_TOPIC_ARN   = aws_sns_topic.unused_token_alerts.arn
      UNUSED_TOKEN_THRESHOLD_MINUTES = "15"
      TRANSLATION_BUCKET             = module.taaops_translation.input_bucket_name
      BEDROCK_MODEL_ID               = var.bedrock_claude_model_id
      SOAR_PROMPT_PARAM_NAME         = "/bedrock/soar-prompt"
      SOAR_MAX_OUTPUT_TOKENS         = "300"
      SOAR_TEMPERATURE               = "0.3"
      SOAR_MAX_FINDINGS_IN_PROMPT    = "5"
      SOAR_TARGET_WORDS              = "0"
      SOAR_MAX_BULLETS_PER_SECTION   = "0"
      SOAR_RISK_FOCUS                = "all"
      SOAR_GENERATE_ON_EMPTY         = "true"
    }
  }
}

resource "aws_sns_topic" "unused_token_alerts" {
  name = "unused-token-alerts"
}

resource "aws_sns_topic_subscription" "unused_token_alerts_email" {
  topic_arn = aws_sns_topic.unused_token_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
}

output "UnusedTokenDetectorFunction" {
  value       = aws_lambda_function.unused_token_detector.arn
  description = "UnusedTokenDetectorFunction function name"
}

output "UnusedTokenAlertTopicARN" {
  value       = aws_sns_topic.unused_token_alerts.arn
  description = "UnusedTokenAlertTopicARN ARN"
}


resource "aws_iam_role_policy" "unused_token_detector_access" {
  name = "unused-token-detector-access"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadTokenTracking"
        Effect = "Allow"
        Action = [
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.dynamoDb_token_tracking.arn
        ]
      },
      {
        Sid    = "AllowPublishUnusedTokenAlerts"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.unused_token_alerts.arn
        ]
      },
      {
        Sid    = "AllowWriteTranslationSoarReports"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${module.taaops_translation.input_bucket_arn}/*"
        ]
      },
      {
        Sid    = "AllowReadSoarPromptParameter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/bedrock/soar-prompt"
        ]
      },
      {
        Sid    = "AllowBedrockInvokeModel"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/bedrock/waf-bedrock-analyzer-prompt"
        ]
      }
    ]
  })
}

# Revoke unused tokens after 5 minutes through EventBridge
data "archive_file" "revoke_token" {
  type        = "zip"
  source_file = "./src/revoke_token.py"
  output_path = "./lambda/revoke_token.zip"
}

resource "aws_lambda_function" "revoke_token" {
  filename      = data.archive_file.revoke_token.output_path
  function_name = "revoke_token_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "revoke_token.lambda_handler"
  code_sha256   = data.archive_file.revoke_token.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE      = aws_dynamodb_table.dynamoDb_token_tracking.name
      TOKEN_CLEANUP_AGE_MINUTES = "5"
    }
  }
}


# Immediate revoke function for Bedrock contract testing - can be invoked by EventBridge Scheduler or other triggers to immediately revoke tokens based on certain conditions or events.
data "archive_file" "immediate_revoke_66" {
  type        = "zip"
  source_file = "./src/immediate_revoke_66.py"
  output_path = "./lambda/immediate_revoke_66.zip"
}

resource "aws_lambda_function" "immediate_revoke_66" {
  filename      = data.archive_file.immediate_revoke_66.output_path
  function_name = "immediate_revoke_66_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "immediate_revoke_66.lambda_handler"
  code_sha256   = data.archive_file.immediate_revoke_66.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      TOKEN_TRACKING_TABLE   = aws_dynamodb_table.dynamoDb_token_tracking.name
      TOKEN_REVOCATION_TABLE = aws_dynamodb_table.dynamoDb_token_revocation.name
    }
  }
}




/*
  environment {
    variables = {
      ENVIRONMENT = "development"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "development"
    Application = aws_lambda_function.get_token.function_name
  }
*/
