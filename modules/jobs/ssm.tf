# SSM handshake parameters — the seam between this control-plane root and
# the worker roots (e.g. the stability_ai workstation repo). Workers read
# these instead of hardcoding queue URLs / table names, so the two Terraform
# roots never share state. Plain Strings: configuration, not secrets.

resource "aws_ssm_parameter" "queue_urls" {
  name        = "/jobs/queue-urls"
  description = "JSON map of job type -> SQS queue URL (jobs module handshake)"
  type        = "String"
  value       = jsonencode({ for t, q in aws_sqs_queue.job_queue : t => q.url })

  tags = var.common_tags
}

resource "aws_ssm_parameter" "table_name" {
  name        = "/jobs/table-name"
  description = "DynamoDB jobs table name (jobs module handshake)"
  type        = "String"
  value       = aws_dynamodb_table.jobs.name

  tags = var.common_tags
}
