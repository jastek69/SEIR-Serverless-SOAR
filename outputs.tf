output "invoke_node_lambda" {
  value = aws_lambda_function.node_lambda.arn
}

output "invoke_python_lambda" {
  value = aws_lambda_function.python_lambda.arn
}

# Invoke URL for API Gateway
# The Invoke URL for an Amazon API Gateway in Terraform is an attribute exported by deployment or stage resources that provides the base endpoint for accessing the API. 
# Only Stage exports the invoke URL, not the REST API itself. This is because the stage is what provides the URL path and deployment context for the API.
output "api_python_invoke_url" {
  value = aws_api_gateway_stage.PythonStage.invoke_url
}

output "api_node_invoke_url" {
  value = aws_api_gateway_stage.NodeStage.invoke_url
}

# Logging outputs for Lambda and WAF
output "python_lambda_log_group" {
  value = "/aws/lambda/${aws_lambda_function.python_lambda.function_name}"
}

output "node_lambda_log_group" {
  value = "/aws/lambda/${aws_lambda_function.node_lambda.function_name}"
}

output "python_api_gateway_access_log_group" {
  value       = aws_cloudwatch_log_group.python_api_gateway_access_logs.name
  description = "API Gateway access log group for the Python REST API prod stage"
}

output "node_api_gateway_access_log_group" {
  value       = aws_cloudwatch_log_group.node_api_gateway_access_logs.name
  description = "API Gateway access log group for the Node REST API prod stage"
}

output "incident_reports_bucket_name" {
  value       = aws_s3_bucket.taaops_ir_reports_bucket.bucket
  description = "S3 bucket that stores incident reports and translated report artifacts"
}

output "waf_logs_bucket" {
  value       = var.enable_waf && var.waf_log_destination == "s3" ? aws_s3_bucket.aws-waf-logs-cf-dest[0].bucket : "N/A"
  description = "WAF logs bucket (only when WAF logging destination is s3)"
}

# For Cloudwatch WAF logging configuration when waf_log_destination = "cloudwatch"
output "waf_log_group" {
  value       = var.enable_waf && var.waf_log_destination == "cloudwatch" ? data.aws_cloudwatch_log_group.taaops_cw_waf_log_group[0].name : "N/A"
  description = "WAF CloudWatch log group (when destination is cloudwatch)"
}


# EventBridge and outputs
output "unused_token_schedule_arn" {
  value       = aws_scheduler_schedule.unused_token_schedule.arn
  description = "ARN of the EventBridge Scheduler schedule for invoking the unused token detector Lambda function every 5 minutes."
}

output "unused_token_schedule_name" {
  value       = aws_scheduler_schedule.unused_token_schedule.name
  description = "Name of the EventBridge Scheduler schedule for invoking the unused token detector Lambda function every 5 minutes."
}
output "unused_token_schedule_target_function" {
  value       = aws_lambda_function.unused_token_detector.arn
  description = "The ARN of the Lambda function being invoked from EventBridge Scheduler"
}

# Cognito outputs for user management and token flows
output "cognito_admin_user_pool_id" {
  value       = aws_cognito_user_pool.cognito_rbac_pool.id
  description = "Cognito admin user pool ID"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.cognito_user_pool.id
  description = "Cognito user pool ID"
}

output "cognito_admin_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.cognito_rbac_pool_client.id
  description = "Cognito admin app client ID"
}

output "cognito_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.cognito_user_pool_client.id
  description = "Cognito user app client ID"
}

output "cognito_admin_issuer_url" {
  value = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.cognito_rbac_pool.id}"
}

output "cognito_user_issuer_url" {
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.cognito_rbac_pool.id}"
  description = "OIDC issuer URL for user pool"
}
