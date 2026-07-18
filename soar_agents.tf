# =============================================================================
# Phase 12 — SOAR agent pipeline
#
#   WAF telemetry (waf_bedrock_analyzer -> waf-events table)
#     -> waf-threat-correlation-agent (hourly schedule)
#     -> waf-correlation-findings table + EventBridge custom event
#          source: seir.waf.correlation, detail-type: WAF Threat Finding Created
#     -> soar-response-agent (MEDIUM/HIGH rule; CRITICAL rule also fans out to
#        the critical-alert SNS topic)
#     -> security-incidents table + SOC SNS notification
#
#   executive-dashboard-agent (manual invoke) reads all three tables and writes
#   PDF+JSON executive reports to S3 under executive-reports/.
#
# Each agent gets its own least-privilege IAM role (jobs-module pattern), not
# the shared lambda_execution_role.
# =============================================================================

# --- SNS topics --------------------------------------------------------------

resource "aws_sns_topic" "soar_notifications" {
  name = "soar-response-notifications"

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_sns_topic_subscription" "soar_notifications_email" {
  topic_arn = aws_sns_topic.soar_notifications.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
}

resource "aws_sns_topic" "critical_alerts" {
  name = "critical-alert"

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_sns_topic_subscription" "critical_alerts_email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
}

# EventBridge must be allowed to publish raw CRITICAL findings to the topic.
resource "aws_sns_topic_policy" "critical_alerts_events" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgePublish"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.critical_alerts.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.soar_critical.arn }
      }
    }]
  })
}

# =============================================================================
# WAF Threat Correlation Agent
# =============================================================================

resource "aws_iam_role" "correlation_agent" {
  name = "waf-threat-correlation-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_iam_role_policy_attachment" "correlation_agent_logs" {
  role       = aws_iam_role.correlation_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "correlation_agent_access" {
  name = "waf-threat-correlation-agent-access"
  role = aws_iam_role.correlation_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadWafEvents"
        Effect   = "Allow"
        Action   = ["dynamodb:Scan"]
        Resource = aws_dynamodb_table.dynamoDb_waf_events.arn
      },
      {
        Sid      = "WriteFindings"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.waf_correlation_findings.arn
      },
      {
        Sid      = "InvokeBedrock"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*" # cross-region inference profiles resolve to region-spanning model ARNs
      },
      {
        Sid      = "EmitFindingEvents"
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
      }
    ]
  })
}

data "archive_file" "correlation_agent" {
  type        = "zip"
  source_file = "${path.module}/agent/waf_threat_correlation_agent.py"
  output_path = "${path.module}/lambda/waf_threat_correlation_agent.zip"
}

resource "aws_lambda_function" "correlation_agent" {
  filename         = data.archive_file.correlation_agent.output_path
  source_code_hash = data.archive_file.correlation_agent.output_base64sha256
  function_name    = "waf-threat-correlation-agent"
  role             = aws_iam_role.correlation_agent.arn
  handler          = "waf_threat_correlation_agent.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 120 # scan + Bedrock correlation call
  memory_size      = 512

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.dynamoDb_waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      BEDROCK_MODEL_ID           = var.bedrock_waf_model_id
      CORRELATION_WINDOW_MINUTES = "60"
      MINIMUM_EVENT_COUNT        = "3"
      MAX_EVENTS                 = "500"
      EVENT_BUS_NAME             = "default"
    }
  }

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_cloudwatch_log_group" "correlation_agent" {
  name              = "/aws/lambda/${aws_lambda_function.correlation_agent.function_name}"
  retention_in_days = 60
}

# Hourly run to match the 60-minute correlation window.
resource "aws_scheduler_schedule" "correlation_agent" {
  name       = "Invoke-waf-threat-correlation-agent"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(60 minutes)"

  target {
    arn      = aws_lambda_function.correlation_agent.arn
    role_arn = aws_iam_role.correlation_agent_schedule.arn

    input = jsonencode({
      source = "eventbridge-scheduler"
    })
  }
}

resource "aws_iam_role" "correlation_agent_schedule" {
  name = "waf-threat-correlation-schedule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_iam_role_policy" "correlation_agent_schedule" {
  name = "waf-threat-correlation-schedule-policy"
  role = aws_iam_role.correlation_agent_schedule.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.correlation_agent.arn
    }]
  })
}

# =============================================================================
# SOAR Response Agent
# =============================================================================

resource "aws_iam_role" "soar_response_agent" {
  name = "soar-response-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_iam_role_policy_attachment" "soar_response_agent_logs" {
  role       = aws_iam_role.soar_response_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "soar_response_agent_access" {
  name = "soar-response-agent-access"
  role = aws_iam_role.soar_response_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAndUpdateFindings"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.waf_correlation_findings.arn
      },
      {
        Sid      = "CreateIncidents"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.security_incidents.arn
      },
      {
        Sid      = "NotifySoc"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.soar_notifications.arn
      },
      {
        Sid      = "InvokeBedrock"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "soar_response_agent" {
  type        = "zip"
  source_file = "${path.module}/src/soar_response_agent.py"
  output_path = "${path.module}/lambda/soar_response_agent.zip"
}

resource "aws_lambda_function" "soar_response_agent" {
  filename         = data.archive_file.soar_response_agent.output_path
  source_code_hash = data.archive_file.soar_response_agent.output_base64sha256
  function_name    = "soar-response-agent"
  role             = aws_iam_role.soar_response_agent.arn
  handler          = "soar_response_agent.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name
      SNS_TOPIC_ARN              = aws_sns_topic.soar_notifications.arn
      BEDROCK_MODEL_ID           = var.bedrock_waf_model_id
      ENABLE_BEDROCK             = "true"
    }
  }

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_cloudwatch_log_group" "soar_response_agent" {
  name              = "/aws/lambda/${aws_lambda_function.soar_response_agent.function_name}"
  retention_in_days = 60
}

# --- EventBridge routing rules ----------------------------------------------

resource "aws_cloudwatch_event_rule" "soar_medium_high" {
  name        = "soar-finding-medium-high"
  description = "Routes MEDIUM/HIGH WAF threat findings to the SOAR response agent"

  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["MEDIUM", "HIGH"]
    }
  })
}

resource "aws_cloudwatch_event_target" "soar_medium_high_lambda" {
  rule = aws_cloudwatch_event_rule.soar_medium_high.name
  arn  = aws_lambda_function.soar_response_agent.arn
}

resource "aws_lambda_permission" "soar_medium_high" {
  statement_id  = "AllowSoarMediumHighRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.soar_medium_high.arn
}

resource "aws_cloudwatch_event_rule" "soar_critical" {
  name        = "soar-finding-critical"
  description = "Routes CRITICAL WAF threat findings to the SOAR response agent and the critical-alert topic"

  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["CRITICAL"]
    }
  })
}

resource "aws_cloudwatch_event_target" "soar_critical_lambda" {
  rule = aws_cloudwatch_event_rule.soar_critical.name
  arn  = aws_lambda_function.soar_response_agent.arn
}

resource "aws_cloudwatch_event_target" "soar_critical_sns" {
  rule = aws_cloudwatch_event_rule.soar_critical.name
  arn  = aws_sns_topic.critical_alerts.arn
}

resource "aws_lambda_permission" "soar_critical" {
  statement_id  = "AllowSoarCriticalRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.soar_critical.arn
}

# =============================================================================
# Executive Dashboard Agent (PDF + JSON reports to S3)
# =============================================================================

resource "aws_s3_bucket" "executive_reports" {
  bucket        = "${var.project_name}-executive-reports-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_s3_bucket_public_access_block" "executive_reports" {
  bucket = aws_s3_bucket.executive_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "executive_dashboard_agent" {
  name = "executive-dashboard-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_iam_role_policy_attachment" "executive_dashboard_agent_logs" {
  role       = aws_iam_role.executive_dashboard_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "executive_dashboard_agent_access" {
  name = "executive-dashboard-agent-access"
  role = aws_iam_role.executive_dashboard_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecurityData"
        Effect = "Allow"
        Action = ["dynamodb:Scan"]
        Resource = [
          aws_dynamodb_table.dynamoDb_waf_events.arn,
          aws_dynamodb_table.waf_correlation_findings.arn,
          aws_dynamodb_table.security_incidents.arn
        ]
      },
      {
        Sid      = "InvokeBedrock"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
      {
        Sid      = "WriteExecutiveReports"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.executive_reports.arn}/executive-reports/*"
      }
    ]
  })
}

# reportlab is not in the managed runtime; package it with the function code.
resource "terraform_data" "executive_dashboard_build" {
  triggers_replace = {
    source       = filesha256("${path.module}/agent/executive_dashboard_agent.py")
    dependencies = "reportlab==4.4.3"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      rm -rf "${path.module}/build/executive_dashboard"
      mkdir -p "${path.module}/build/executive_dashboard"
      python -m pip install --quiet --no-compile \
        --platform manylinux2014_x86_64 --implementation cp --python-version 3.12 --only-binary=:all: \
        --target "${path.module}/build/executive_dashboard" reportlab==4.4.3
      cp "${path.module}/agent/executive_dashboard_agent.py" "${path.module}/build/executive_dashboard/"
    EOT
  }
}

data "archive_file" "executive_dashboard_agent" {
  depends_on  = [terraform_data.executive_dashboard_build]
  type        = "zip"
  source_dir  = "${path.module}/build/executive_dashboard"
  output_path = "${path.module}/lambda/executive_dashboard_agent.zip"
}

resource "aws_lambda_function" "executive_dashboard_agent" {
  filename         = data.archive_file.executive_dashboard_agent.output_path
  source_code_hash = data.archive_file.executive_dashboard_agent.output_base64sha256
  function_name    = "executive-dashboard-agent"
  role             = aws_iam_role.executive_dashboard_agent.arn
  handler          = "executive_dashboard_agent.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 120
  memory_size      = 1024

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.dynamoDb_waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name
      REPORT_BUCKET              = aws_s3_bucket.executive_reports.bucket
      REPORT_PREFIX              = "executive-reports"
      BEDROCK_MODEL_ID           = var.bedrock_waf_model_id
      ENABLE_BEDROCK             = "true"
      REPORT_PERIOD_HOURS        = "24"
      MAX_ITEMS_PER_TABLE        = "5000"
      ORGANIZATION_NAME          = "SEIR Cloud Security"
      REPORT_TITLE               = "Executive Security Report"
    }
  }

  tags = merge(var.common_tags, { Component = "soar" })
}

resource "aws_cloudwatch_log_group" "executive_dashboard_agent" {
  name              = "/aws/lambda/${aws_lambda_function.executive_dashboard_agent.function_name}"
  retention_in_days = 60
}

# --- Outputs -----------------------------------------------------------------

output "soar_notifications_topic_arn" {
  description = "SNS topic the SOAR response agent publishes SOC notifications to"
  value       = aws_sns_topic.soar_notifications.arn
}

output "critical_alerts_topic_arn" {
  description = "SNS topic that receives raw CRITICAL finding events from EventBridge"
  value       = aws_sns_topic.critical_alerts.arn
}

output "executive_reports_bucket" {
  description = "S3 bucket receiving executive PDF/JSON reports"
  value       = aws_s3_bucket.executive_reports.bucket
}
