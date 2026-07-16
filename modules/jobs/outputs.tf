# Jobs Module Outputs

output "deployment_trigger_hash" {
  description = "Wire this into the existing aws_api_gateway_deployment triggers — REST v1 only picks up the /jobs routes on a redeployment."
  value = sha1(jsonencode({
    jobs_resource      = aws_api_gateway_resource.jobs
    job_id_resource    = aws_api_gateway_resource.job_id
    submit_method      = aws_api_gateway_method.submit_job
    submit_integration = aws_api_gateway_integration.submit_job
    status_method      = aws_api_gateway_method.get_job_status
    status_integration = aws_api_gateway_integration.get_job_status
  }))
}

output "queue_urls" {
  description = "Job type -> SQS queue URL"
  value       = { for t, q in aws_sqs_queue.job_queue : t => q.url }
}

output "queue_arns" {
  description = "Job type -> SQS queue ARN (for worker-role IAM scoping)"
  value       = { for t, q in aws_sqs_queue.job_queue : t => q.arn }
}

output "dlq_arns" {
  description = "Job type -> DLQ ARN (the Bedrock failure reporter subscribes here)"
  value       = { for t, q in aws_sqs_queue.job_dlq : t => q.arn }
}

output "jobs_table_name" {
  description = "DynamoDB jobs table name"
  value       = aws_dynamodb_table.jobs.name
}

output "jobs_table_arn" {
  description = "DynamoDB jobs table ARN (for worker-role IAM scoping)"
  value       = aws_dynamodb_table.jobs.arn
}

output "submit_lambda_name" {
  description = "Submit Lambda function name"
  value       = aws_lambda_function.submit_job.function_name
}

output "status_lambda_name" {
  description = "Status Lambda function name"
  value       = aws_lambda_function.get_job_status.function_name
}

output "detector_lambda_name" {
  description = "Stuck-job detector Lambda function name"
  value       = aws_lambda_function.stuck_job_detector.function_name
}

output "reporter_lambda_name" {
  description = "Bedrock failure-reporter Lambda function name"
  value       = aws_lambda_function.failure_reporter.function_name
}

output "reporter_role_arn" {
  description = "Failure-reporter role ARN — add to the workstation bucket policy's exception list if bucket_access_mode is ever restricted"
  value       = aws_iam_role.failure_reporter.arn
}
