# One queue + DLQ per job type, driven entirely by var.queue_visibility_timeouts.

resource "aws_sqs_queue" "job_dlq" {
  for_each = var.queue_visibility_timeouts

  name                      = "${local.name_prefix}-${each.key}-dlq"
  message_retention_seconds = 1209600 # 14 days — max, so failures keep evidence

  # Lambda event source mappings require source-queue visibility >= the
  # consumer function's timeout (reporter = 120s); 6x is the AWS-recommended
  # margin so a slow Bedrock call never causes duplicate reports.
  visibility_timeout_seconds = 720

  tags = merge(var.common_tags, {
    Name    = "${local.name_prefix}-${each.key}-dlq"
    JobType = each.key
  })
}

resource "aws_sqs_queue" "job_queue" {
  for_each = var.queue_visibility_timeouts

  name                       = "${local.name_prefix}-${each.key}"
  visibility_timeout_seconds = each.value
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.job_dlq[each.key].arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(var.common_tags, {
    Name    = "${local.name_prefix}-${each.key}"
    JobType = each.key
  })
}
