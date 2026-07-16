# Jobs Module — job-submission control plane (Phase 2)
#
# One SQS queue + DLQ per job type, a DynamoDB jobs table, submit/status
# Lambdas on the existing PythonAPI, an EventBridge stuck-job detector, and
# the SSM handshake parameters the worker roots read.
#
# Frozen contract (do not change without updating every worker):
#   SQS message body : {"job_id": str, "type": str, "params": dict}
#   DynamoDB statuses: queued | running | succeeded | failed | stalled
#   Workers heartbeat updated_at every 60-120s while running.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = var.name_prefix

  # Every job type must have an entitlement path; catches a
  # queue_visibility_timeouts entry added without group_entitlements.
  entitled_types = distinct(flatten(values(var.group_entitlements)))
}
