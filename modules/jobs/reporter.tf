# Bedrock failure reporter (Phase 2 item 2.3) — post-mortems for
# dead-lettered and stalled jobs, written to the workstation bucket under
# reports/jobs/<job_id>.md.
#
# ⚠ Cross-root note: the report bucket belongs to the stability_ai root. If
# its bucket_access_mode is ever set to a restrictive mode, this reporter's
# role must be added to that bucket policy's exception list or PutObject
# gets an explicit Deny.

# Prompt template — versioned configuration, edited in SSM, not in code.
# ignore_changes keeps Terraform from reverting console/CLI edits; the value
# here is only the first-deploy seed.
resource "aws_ssm_parameter" "failure_prompt" {
  name        = var.failure_prompt_param_name
  description = "Prompt template for the jobs failure post-mortem reporter"
  type        = "String"
  value       = <<-PROMPT
    You are an SRE writing a concise post-mortem for a failed GPU generation job
    in a queue-driven ComfyUI render farm. You will receive a JSON context block
    with the trigger (dead-lettered or stalled), the job's DynamoDB record, and
    any control-plane log excerpts.

    Write a Markdown report with exactly these sections:
    # Job Failure Post-Mortem
    ## Summary        (2-3 sentences: what job, what happened, when)
    ## Timeline       (from created_at/updated_at and log timestamps)
    ## Probable Cause (reason from the evidence; state confidence; if evidence
                       is thin, say what is missing rather than speculating)
    ## Recommended Actions (numbered, most valuable first, each one concrete)

    Be factual and practical. Do not invent log lines or metrics that are not
    in the context block.
  PROMPT

  tags = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# --- IAM — own role: this is the only jobs Lambda that touches Bedrock and
# --- the other root's bucket, so it gets its own blast radius.

resource "aws_iam_role" "failure_reporter" {
  name               = "${local.name_prefix}-reporter-role"
  assume_role_policy = data.aws_iam_policy_document.jobs_lambda_assume.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "failure_reporter_logs" {
  role       = aws_iam_role.failure_reporter.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "failure_reporter_access" {
  name = "${local.name_prefix}-reporter-access"
  role = aws_iam_role.failure_reporter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid      = "ConsumeDlqs"
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = [for q in aws_sqs_queue.job_dlq : q.arn]
      },
      {
        Sid      = "ReadAndStampJobRecords"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = [aws_dynamodb_table.jobs.arn]
      },
      {
        Sid    = "ReadPromptAndBucketParams"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          aws_ssm_parameter.failure_prompt.arn,
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/stability-matrix/bucket"
        ]
      },
      {
        Sid    = "SearchControlPlaneLogs"
        Effect = "Allow"
        Action = ["logs:FilterLogEvents"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.submit_job.function_name}:*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.stuck_job_detector.function_name}:*"
        ]
      },
      {
        Sid      = "InvokeBedrock"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      }
      ],
      var.reports_bucket_name != "" ? [
        {
          Sid      = "WriteReports"
          Effect   = "Allow"
          Action   = ["s3:PutObject"]
          Resource = ["arn:aws:s3:::${var.reports_bucket_name}/reports/jobs/*"]
        }
        ] : [
        # Bucket unknown at plan time (resolved at runtime from SSM):
        # constrain by object prefix instead of bucket name.
        {
          Sid      = "WriteReportsAnyBucketPrefixScoped"
          Effect   = "Allow"
          Action   = ["s3:PutObject"]
          Resource = ["arn:aws:s3:::*/reports/jobs/*"]
        }
    ])
  })
}

# --- Lambda ----------------------------------------------------------------

data "archive_file" "failure_reporter" {
  type        = "zip"
  source_file = "${path.module}/lambda/failure_reporter.py"
  output_path = "${path.module}/lambda/failure_reporter.zip"
}

resource "aws_lambda_function" "failure_reporter" {
  filename      = data.archive_file.failure_reporter.output_path
  function_name = "${local.name_prefix}-failure-reporter"
  role          = aws_iam_role.failure_reporter.arn
  handler       = "failure_reporter.lambda_handler"
  code_sha256   = data.archive_file.failure_reporter.output_base64sha256

  runtime     = var.lambda_runtime
  timeout     = 120 # Bedrock generation + log search
  memory_size = var.lambda_memory

  environment {
    variables = {
      JOBS_TABLE        = aws_dynamodb_table.jobs.name
      BEDROCK_MODEL_ID  = var.bedrock_model_id
      PROMPT_PARAM_NAME = aws_ssm_parameter.failure_prompt.name
      REPORTS_BUCKET    = var.reports_bucket_name
      LOG_GROUPS = join(",", [
        "/aws/lambda/${aws_lambda_function.submit_job.function_name}",
        "/aws/lambda/${aws_lambda_function.stuck_job_detector.function_name}"
      ])
    }
  }

  tags = var.common_tags
}

# --- Triggers ----------------------------------------------------------------

# 1. DLQ arrivals — worker crashed / message exhausted its receives
resource "aws_lambda_event_source_mapping" "dlq_to_reporter" {
  for_each = var.queue_visibility_timeouts

  event_source_arn = aws_sqs_queue.job_dlq[each.key].arn
  function_name    = aws_lambda_function.failure_reporter.arn
  batch_size       = 5
}

# 2. Detector JobStalled findings
resource "aws_cloudwatch_event_rule" "job_stalled" {
  name        = "${local.name_prefix}-stalled"
  description = "Route detector JobStalled findings to the failure reporter"

  event_pattern = jsonencode({
    source        = ["jobs.detector"]
    "detail-type" = ["JobStalled"]
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "job_stalled" {
  rule = aws_cloudwatch_event_rule.job_stalled.name
  arn  = aws_lambda_function.failure_reporter.arn
}

resource "aws_lambda_permission" "job_stalled" {
  statement_id  = "AllowExecutionFromEventBridgeJobStalled"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failure_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.job_stalled.arn
}
