
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
  default     = {
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



# Cognito variables
variable "cognito_user_pool_arn" {
  description = "Direct override for Cognito user pool ARN. If set, this value is used by API Gateway authorizers."
  type        = string
  default     = ""
}

variable "cognito_state_enabled" {
  description = "Enable reading Cognito outputs from remote Terraform state in S3."
  type        = bool
  default     = false
}

variable "cognito_state_bucket" {
  description = "S3 bucket for the Terraform state that contains Cognito outputs."
  type        = string
  default     = ""
}

variable "cognito_state_key" {
  description = "S3 state key for the Terraform state that contains Cognito outputs."
  type        = string
  default     = ""
}

variable "cognito_state_region" {
  description = "AWS region for the Terraform state backend containing Cognito outputs."
  type        = string
  default     = "us-west-2"
}

variable "cognito_state_output_name" {
  description = "Output name in the Cognito Terraform state that holds the user pool ARN."
  type        = string
  default     = "cognito_user_pool_arn"
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
