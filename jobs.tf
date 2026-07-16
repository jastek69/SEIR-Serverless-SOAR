# Jobs control plane (Phase 2 of the GenAI media infrastructure) —
# POST /jobs + GET /jobs/{job_id} on the existing PythonAPI, one SQS
# queue + DLQ per job type, DynamoDB jobs table, stuck-job detector,
# and the /jobs/* SSM handshake parameters worker roots read.
#
# Adding a new job type = one entry in queue_visibility_timeouts +
# group_entitlements below, plus a worker that honors the contract.

module "jobs" {
  source = "./modules/jobs"

  region      = var.region
  common_tags = var.common_tags

  # Attach to the existing PythonAPI + Cognito authorizer
  rest_api_id               = aws_api_gateway_rest_api.PythonAPI.id
  rest_api_root_resource_id = aws_api_gateway_rest_api.PythonAPI.root_resource_id
  rest_api_execution_arn    = aws_api_gateway_rest_api.PythonAPI.execution_arn
  authorizer_id             = aws_api_gateway_authorizer.python_cognito.id
  authorization_scopes      = ["${aws_cognito_resource_server.rbac_api_resource_server.identifier}/user"]

  queue_visibility_timeouts = {
    comfyui_gen = 900
  }

  group_entitlements = {
    user = ["comfyui_gen"]
    m2m  = ["comfyui_gen"]
  }

  # Failure reporter (Bedrock post-mortems). The reports bucket lives in the
  # stability_ai workstation root — named explicitly here so the reporter's
  # PutObject stays scoped to that one bucket. Keep in sync with that root's
  # bucket_name var. Sonnet (the SOAR report model), not the cheaper WAF Haiku:
  # post-mortems are low-volume and benefit from the better reasoning.
  reports_bucket_name = "stability-matrix-outputs"
  bedrock_model_id    = var.bedrock_claude_model_id
}

output "jobs_queue_urls" {
  description = "Job type -> SQS queue URL"
  value       = module.jobs.queue_urls
}

output "jobs_table_name" {
  description = "DynamoDB jobs table name"
  value       = module.jobs.jobs_table_name
}
