# Scheduled sweep for stalled jobs (workers heartbeat updated_at; silence
# beyond the threshold means the worker died or hung).

resource "aws_cloudwatch_event_rule" "stuck_job_sweep" {
  name                = "${local.name_prefix}-stuck-sweep"
  description         = "Periodic stuck-job detector sweep for the jobs table"
  schedule_expression = var.detector_schedule_expression

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "stuck_job_sweep" {
  rule = aws_cloudwatch_event_rule.stuck_job_sweep.name
  arn  = aws_lambda_function.stuck_job_detector.arn
}

resource "aws_lambda_permission" "stuck_job_sweep" {
  statement_id  = "AllowExecutionFromEventBridgeStuckSweep"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stuck_job_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stuck_job_sweep.arn
}
