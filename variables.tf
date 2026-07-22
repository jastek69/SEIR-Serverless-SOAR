
variable "access_key" {
  description = "Access key to AWS console"
}

variable "secret_key" {
  description = "Secret key to AWS console"
}


variable "project" {
  default     = "lambda-waf"
  description = "The name of the project"
  type        = string
}

variable "project_name" {
  default     = "taaops-lambda-waf"
  description = "The name of the project for resource naming"
  type        = string
}

variable "app_name" {
  default     = "image_processor"
  description = "The name of the application"
  type        = string
}


# Oregon for Bedrock implementation in West
variable "region" {
  default     = "us-west-2"
  description = "Primary AWS region for all workload resources"
  type        = string
}


# FORCE DESTROY SETTING for Dev and Prod
variable "force_destroy" {
  default     = true
  description = "Whether to force destroy resources that may have dependencies (use with caution)"
  type        = bool
}


# API Gateway logging variables
# Set to False for Prod to avoid potential performance impact and cost of detailed data trace logging; can be enabled for Dev and Staging for troubleshooting.
variable "api_data_trace_enabled" {
  default     = true
  description = "Whether to enable data trace logging for API Gateway"
  type        = bool
}

# Legacy variable retained for compatibility; providers now use var.region.
variable "region_waf_cf" {
  # default     = "us-east-1"
  default     = "us-west-2"
  description = "Legacy WAF/CloudFront region override (currently unused)"
  type        = string
}

variable "translation_kms_key_arn" {
  description = "KMS key ARN for the translation module S3/log encryption access"
  type        = string
  default     = "arn:aws:kms:us-west-2:015195098145:key/fd93b975-d339-407e-8745-9149a1b2e973"
}


variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "lambda-rbac-bedrock",
    Environment = "dev",
    Owner       = "taaops"
  }
}


# Lambda variables
variable "lambda_runtime" {
  default     = "python3.12"
  description = "The runtime environment for the Lambda function"
  type        = string
}

variable "lambda_timeout" {
  default     = 30
  description = "The timeout for the Lambda function in seconds"
  type        = number
}

variable "lambda_memory" {
  default     = 512
  description = "The memory size for the Lambda function in MB"
  type        = number
}


variable "environment" {
  default     = "dev"
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}


# Database - Phase 11 RDS MySQL intake
variable "rds_db_username" {
  description = "Master username for the Phase 11 intake RDS MySQL instance"
  type        = string
  default     = "admin"
}

variable "rds_db_name" {
  description = "Initial database created on the Phase 11 intake RDS MySQL instance"
  type        = string
  default     = "lab11"
}

variable "rds_instance_class" {
  description = "Instance class for the Phase 11 intake RDS MySQL instance"
  type        = string
  default     = "db.t3.micro"
}


# Database - Aurora variables
variable "aurora_username" {
  description = "The username for the Aurora database"
  type        = string
}

variable "aurora_password" {
  description = "The password for the Aurora database"
  type        = string
}


# SNS SQS
variable "alert_email_address" {
  description = "Email address for SNS notifications"
  type        = string
}



# CloudFront and WAF variables

variable "enable_waf" {
  default     = true
  description = "Whether to enable the WAF Web ACL and logging configuration"
  type        = bool
}

variable "waf_log_destination" {
  description = "WAF log destination: cloudwatch, firehose, or s3."
  type        = string
  default     = "s3"
  validation {
    condition     = contains(["cloudwatch", "firehose", "s3"], var.waf_log_destination)
    error_message = "waf_log_destination must be cloudwatch, firehose, or s3."
  }
}

variable "waf_log_retention_days" {
  description = "CloudWatch Logs retention days for WAF logging."
  type        = number
  default     = 30
}

# WAF rate-based rule variables
variable "waf_rate_limit_action" {
  description = "Action for WAF rate-based rule: block or count."
  type        = string
  default     = "block"
  validation {
    condition     = contains(["block", "count"], var.waf_rate_limit_action)
    error_message = "waf_rate_limit_action must be block or count."
  }
}

# WAF Block Mode: Default implementation blocks requests that exceed the rate limit, but you can set to "count" for monitoring and tuning before enforcing blocking.
variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute window per source IP for WAF rate-based rule."
  type        = number
  default     = 100
}

# --- Unused-token detector / SOAR (FinOps knobs — turn these down while
# other parts of the stack are under test; the token pipeline itself is
# already verified working) ---------------------------------------------

variable "unused_token_schedule_rate_minutes" {
  description = "How often EventBridge Scheduler invokes the unused-token detector. Lower = more current detection but more Lambda/Bedrock invocations."
  type        = number
  default     = 15
}

variable "unused_token_threshold_minutes" {
  description = "Age (minutes) before a tracked token is considered unused and eligible for revocation."
  type        = number
  default     = 15
}

# the detector calls Bedrock and writes a SOAR report every single cycle, even when zero unused tokens are found — 
# this is a recurring cost that can be avoided by setting this to false while other parts of the stack are under test.
# Set it false and the detector only calls Bedrock (and writes a report) when it actually finds something, or when you manually force it with (force_soar: true).
  variable "soar_generate_on_empty" {
  description = "Whether the unused-token detector generates a Bedrock SOAR report even when no stale tokens are found. Set false to cut the recurring Bedrock cost while other parts of the stack are under test."
  type        = bool
  default     = true
}

# --- WAF threat correlation agent (Phase 12) -----------------------------

variable "waf_correlation_schedule_rate_minutes" {
  description = "How often EventBridge Scheduler invokes the WAF threat correlation agent."
  type        = number
  default     = 60
}

variable "waf_correlation_window_minutes" {
  description = "Lookback window (minutes) the correlation agent scans for WAF events. Keep in sync with waf_correlation_schedule_rate_minutes unless you have a specific reason to diverge (e.g. overlap for safety margin)."
  type        = number
  default     = 60
}

variable "waf_correlation_minimum_event_count" {
  description = "Minimum WAF events from one source within the window before correlation flags it."
  type        = number
  default     = 3
}

variable "waf_correlation_max_events" {
  description = "Max WAF events scanned per correlation run."
  type        = number
  default     = 500
}

# --- SOAR response / executive dashboard ----------------------------------

variable "enable_bedrock_soar" {
  description = "Whether the SOAR response and executive-dashboard agents call Bedrock. Set false to cut Bedrock cost while testing other parts of the pipeline (findings/incidents still get created, just without the AI-authored summary)."
  type        = bool
  default     = true
}

variable "executive_report_period_hours" {
  description = "Lookback window (hours) for the executive dashboard report."
  type        = number
  default     = 24
}

variable "executive_report_max_items_per_table" {
  description = "Max items scanned per table when building the executive report."
  type        = number
  default     = 5000
}

variable "executive_report_organization_name" {
  description = "Organization name shown on executive PDF/JSON reports."
  type        = string
  default     = "SEIR Cloud Security"
}

variable "executive_report_title" {
  description = "Title shown on executive PDF/JSON reports."
  type        = string
  default     = "Executive Security Report"
}

# Count Mode variables for testing before blocking
variable "api_throttle_rate_limit" {
  description = "Steady-state requests per second limit for API Gateway stage throttling."
  type        = number
  default     = 25
}


# API GATEWAY variables

# API Gateway stage throttling burst limit for handling traffic spikes; should be >= api_throttle_rate_limit.
variable "api_throttle_burst_limit" {
  description = "Maximum concurrent request burst for API Gateway stage throttling."
  type        = number
  default     = 50
}

variable "api_gateway_access_log_retention_days" {
  description = "CloudWatch Logs retention days for API Gateway REST API access logs."
  type        = number
  default     = 30
}



variable "cognito_user_pool_client_id" {
  description = "Direct override for Cognito user pool client ID. If set, this value is used by API Gateway authorizers."
  type        = string
  default     = ""
}

variable "cognito_user_pool_id" {
  description = "Direct override for Cognito user pool ID for Lambdas that call Cognito APIs."
  type        = string
  default     = ""
}


# Bedrock

## Tokens
variable "soar_max_tokens" {
  description = "Maximum tokens for Bedrock LLM responses in the SOAR module."
  type        = number
  default     = 500
}

## Models

# SOAR Model is currently: Claude Sonnet 4.6
variable "bedrock_claude_model_id" {
  description = "Bedrock model ID for the SOAR module."
  type        = string
  default     = "us.anthropic.claude-sonnet-4-6" # if not read remove `us` and set to anthropic.claude-v2 
}

# WAF Model is currently: Haiku (low cost option)
variable "bedrock_waf_model_id" {
  description = "Bedrock model ID for the WAF analysis module."
  type        = string
  default     = "us.anthropic.claude-haiku-4-5-20251001-v1:0" # if not read remove `us` and set to anthropic.claude-v2 
}