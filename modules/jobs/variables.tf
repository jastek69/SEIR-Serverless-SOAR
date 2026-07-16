# Jobs Module Variables

variable "region" {
  description = "AWS region for the jobs module"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for all jobs-module resource names"
  type        = string
  default     = "taaops-jobs"
}

# ---------------------------------------------------------------------------
# Job types — adding a new job type is ONE entry in each of these two maps
# (plus a worker that honors the contract). Nothing else should change.
# ---------------------------------------------------------------------------

variable "queue_visibility_timeouts" {
  description = "Job type -> SQS visibility timeout in seconds. One queue + DLQ is created per entry. Visibility must exceed the worst-case job duration or the message redelivers mid-run (workers can extend via ChangeMessageVisibility)."
  type        = map(number)
  default = {
    comfyui_gen = 900
  }
}

variable "group_entitlements" {
  description = "Cognito group -> list of job types it may submit. M2M (client_credentials) tokens have no groups and map to the pseudo-group \"m2m\". The admin group / rbac-api-admin scope bypasses this and may submit every type."
  type        = map(list(string))
  default = {
    user = ["comfyui_gen"]
    m2m  = ["comfyui_gen"]
  }
}

# ---------------------------------------------------------------------------
# Attachment points on the existing PythonAPI (REST v1) — passed in from root.
# ---------------------------------------------------------------------------

variable "rest_api_id" {
  description = "ID of the existing REST API the /jobs routes attach to"
  type        = string
}

variable "rest_api_root_resource_id" {
  description = "Root resource ID of the REST API"
  type        = string
}

variable "rest_api_execution_arn" {
  description = "Execution ARN of the REST API (for lambda_permission source_arn)"
  type        = string
}

variable "authorizer_id" {
  description = "ID of the existing Cognito authorizer on the REST API"
  type        = string
}

variable "authorization_scopes" {
  description = "OAuth scopes required on the jobs routes"
  type        = list(string)
  default     = ["rbac-api/user"]
}

# ---------------------------------------------------------------------------
# Behavior knobs
# ---------------------------------------------------------------------------

variable "job_ttl_days" {
  description = "Days before a job record expires from DynamoDB (TTL on expires_at)"
  type        = number
  default     = 30
}

variable "stalled_threshold_seconds" {
  description = "A running job whose updated_at heartbeat is older than this is marked stalled. Workers heartbeat every 60-120s, so this must comfortably exceed 120."
  type        = number
  default     = 600
}

variable "detector_schedule_expression" {
  description = "EventBridge schedule for the stuck-job detector sweep"
  type        = string
  default     = "rate(5 minutes)"
}

variable "dlq_max_receive_count" {
  description = "Deliveries before a message moves to the DLQ"
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# Failure reporter (Bedrock post-mortems)
# ---------------------------------------------------------------------------

variable "bedrock_model_id" {
  description = "Bedrock model ID for failure post-mortems"
  type        = string
  default     = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
}

variable "reports_bucket_name" {
  description = "Bucket the failure reporter writes reports/jobs/<job_id>.md to. Empty = resolve at runtime from the /stability-matrix/bucket SSM handshake param (IAM then falls back to a prefix-scoped wildcard)."
  type        = string
  default     = ""
}

variable "failure_prompt_param_name" {
  description = "SSM parameter holding the failure-reporter prompt template"
  type        = string
  default     = "/bedrock/jobs-failure-prompt"
}

variable "lambda_runtime" {
  description = "Runtime for the jobs-module Lambdas"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout (seconds) for the jobs-module Lambdas"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Memory (MB) for the jobs-module Lambdas"
  type        = number
  default     = 256
}
