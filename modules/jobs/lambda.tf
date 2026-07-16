# Jobs-module Lambdas: submit, status, stuck-job detector.
# Module-scoped IAM role — deliberately NOT the root's shared
# lambda_execution_role, so these functions can touch only jobs resources.

data "aws_iam_policy_document" "jobs_lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "jobs_lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.jobs_lambda_assume.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "jobs_lambda_logs" {
  role       = aws_iam_role.jobs_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "jobs_lambda_access" {
  name = "${local.name_prefix}-lambda-access"
  role = aws_iam_role.jobs_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "JobsTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.jobs.arn,
          "${aws_dynamodb_table.jobs.arn}/index/*"
        ]
      },
      {
        Sid      = "EnqueueJobs"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = [for q in aws_sqs_queue.job_queue : q.arn]
      },
      {
        Sid      = "EmitStalledEvents"
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = ["arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:event-bus/default"]
      }
    ]
  })
}

# --- submit_job -------------------------------------------------------------

data "archive_file" "submit_job" {
  type        = "zip"
  source_file = "${path.module}/lambda/submit_job.py"
  output_path = "${path.module}/lambda/submit_job.zip"
}

resource "aws_lambda_function" "submit_job" {
  filename      = data.archive_file.submit_job.output_path
  function_name = "${local.name_prefix}-submit"
  role          = aws_iam_role.jobs_lambda.arn
  handler       = "submit_job.lambda_handler"
  code_sha256   = data.archive_file.submit_job.output_base64sha256

  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory

  environment {
    variables = {
      JOBS_TABLE         = aws_dynamodb_table.jobs.name
      QUEUE_URLS         = jsonencode({ for t, q in aws_sqs_queue.job_queue : t => q.url })
      GROUP_ENTITLEMENTS = jsonencode(var.group_entitlements)
      JOB_TTL_DAYS       = tostring(var.job_ttl_days)
    }
  }

  tags = var.common_tags
}

# --- get_job_status ---------------------------------------------------------

data "archive_file" "get_job_status" {
  type        = "zip"
  source_file = "${path.module}/lambda/get_job_status.py"
  output_path = "${path.module}/lambda/get_job_status.zip"
}

resource "aws_lambda_function" "get_job_status" {
  filename      = data.archive_file.get_job_status.output_path
  function_name = "${local.name_prefix}-status"
  role          = aws_iam_role.jobs_lambda.arn
  handler       = "get_job_status.lambda_handler"
  code_sha256   = data.archive_file.get_job_status.output_base64sha256

  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory

  environment {
    variables = {
      JOBS_TABLE = aws_dynamodb_table.jobs.name
    }
  }

  tags = var.common_tags
}

# --- stuck_job_detector -----------------------------------------------------

data "archive_file" "stuck_job_detector" {
  type        = "zip"
  source_file = "${path.module}/lambda/stuck_job_detector.py"
  output_path = "${path.module}/lambda/stuck_job_detector.zip"
}

resource "aws_lambda_function" "stuck_job_detector" {
  filename      = data.archive_file.stuck_job_detector.output_path
  function_name = "${local.name_prefix}-stuck-detector"
  role          = aws_iam_role.jobs_lambda.arn
  handler       = "stuck_job_detector.lambda_handler"
  code_sha256   = data.archive_file.stuck_job_detector.output_base64sha256

  runtime     = var.lambda_runtime
  timeout     = 120 # sweep may page through many jobs
  memory_size = var.lambda_memory

  environment {
    variables = {
      JOBS_TABLE                = aws_dynamodb_table.jobs.name
      STATUS_INDEX              = "status-index"
      STALLED_THRESHOLD_SECONDS = tostring(var.stalled_threshold_seconds)
    }
  }

  tags = var.common_tags
}
