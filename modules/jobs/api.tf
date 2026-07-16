# Routes on the EXISTING PythonAPI (REST v1):
#   POST /jobs           -> submit_job
#   GET  /jobs/{job_id}  -> get_job_status
#
# Both use the existing Cognito authorizer + rbac-api/user scope (Layer 1);
# the handlers enforce group/scope entitlements (Layer 2).
#
# ⚠ REST v1 sharp edge: new routes only go live when the API is redeployed.
# Root MUST wire this module's deployment_trigger_hash output into the
# existing aws_api_gateway_deployment triggers — see outputs.tf.

resource "aws_api_gateway_resource" "jobs" {
  rest_api_id = var.rest_api_id
  parent_id   = var.rest_api_root_resource_id
  path_part   = "jobs"
}

resource "aws_api_gateway_resource" "job_id" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.jobs.id
  path_part   = "{job_id}"
}

# --- POST /jobs -------------------------------------------------------------

resource "aws_api_gateway_method" "submit_job" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.jobs.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = var.authorizer_id
  authorization_scopes = var.authorization_scopes
}

resource "aws_api_gateway_integration" "submit_job" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.jobs.id
  http_method = aws_api_gateway_method.submit_job.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.submit_job.invoke_arn

  timeout_milliseconds = 29000
}

resource "aws_lambda_permission" "submit_job" {
  statement_id  = "AllowExecutionFromAPIGatewayJobsSubmit"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit_job.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/POST/jobs"
}

# --- GET /jobs/{job_id} -----------------------------------------------------

resource "aws_api_gateway_method" "get_job_status" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.job_id.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = var.authorizer_id
  authorization_scopes = var.authorization_scopes
}

resource "aws_api_gateway_integration" "get_job_status" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.job_id.id
  http_method = aws_api_gateway_method.get_job_status.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_job_status.invoke_arn

  timeout_milliseconds = 29000
}

resource "aws_lambda_permission" "get_job_status" {
  statement_id  = "AllowExecutionFromAPIGatewayJobsStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_job_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/GET/jobs/*"
}
