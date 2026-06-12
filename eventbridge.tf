

# Python Eventbridge
# Set the Lambda Function as a CloudWatch event target

# Create a log group for the Lambda function with 60 days retention period
resource "aws_cloudwatch_log_group" "token_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.unused_token_detector.function_name}"
  retention_in_days = 60
}



# unused_token_detector Lambda function defined in lambda.tf


# Eventbridge Scheduler for unused token detection - triggers every 5 minutes to check for unused tokens and revoke them
resource "aws_scheduler_schedule" "unused_token_schedule" {
  name       = "Invoke-unused-token-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = aws_lambda_function.unused_token_detector.arn
    role_arn = aws_iam_role.unused_token_schedule_role.arn

      input = jsonencode({
      MessageBody = "Protections invoked by EventBridge Scheduler"
      QueueUrl    = aws_sqs_queue.unused_token_sqs.url
    })
  }
}


# SQS Python Queue
resource "aws_sqs_queue" "unused_token_sqs" {}



resource "aws_iam_role" "unused_token_schedule_role" {
  name = "unused-token-schedule-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "unused_token_schedule_policy" {
  name = "unused-token-schedule-policy"
  role = aws_iam_role.unused_token_schedule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Sid" : "AllowEventBridgeToInvokeLambda",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Effect" : "Allow",
        "Resource" : aws_lambda_function.unused_token_detector.arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "unused_token_schedule_policy_attachment" {
  role       = aws_iam_role.unused_token_schedule_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "LambdaExecutionRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "PublishLogsPolicy"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLambdaFunctionToCreateLogs",
        "Action" : [
          "logs:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.unused_token_detector.function_name}:*"
        ]
      }
    ]
  })
}


# Execute Order 66 on Bad Actors
# Triggered by EventBridge Scheduler or other events to immediately revoke tokens associated with bad actors or suspicious activity.
resource "aws_cloudwatch_event_rule" "immediate_revoke_66_alarm_rule" {
  name        = "immediate-revoke-66-alarm-rule"
  description = "Routes CloudWatch ALARM state changes to immediate revoke Lambda"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

# CloudWatch Event Target for Immediate Revoke Lambda
resource "aws_cloudwatch_event_target" "immediate_revoke_66" {
  arn  = aws_lambda_function.immediate_revoke_66.arn
  rule = aws_cloudwatch_event_rule.immediate_revoke_66_alarm_rule.id

  input_transformer {
    input_paths = {
      alarm_name = "$.detail.alarmName"
      reason     = "$.detail.state.reason"
      request_id = "$.id"
      source     = "$.source"
    }
    input_template = <<EOT
{
  "source": "<source>",
  "reason": "alarm:<alarm_name> <reason>",
  "request_id": "<request_id>",
  "token_hash": "alarm-trigger-placeholder"
}
EOT
  }
}



# Create a log group for the Lambda function with 60 days retention period
resource "aws_cloudwatch_log_group" "immediate_revoke_66_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.immediate_revoke_66.function_name}"
  retention_in_days = 60
}



# revoke_token_66 Lambda function defined in lambda.tf


# Allow the EventBridge rule created to invoke the Lambda function
resource "aws_lambda_permission" "EventBridge_immediate_revoke_66_lambdaPermission" {
  statement_id  = "AllowExecutionFromCloudWatchImmediateRevoke66"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.immediate_revoke_66.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.immediate_revoke_66_alarm_rule.arn
}