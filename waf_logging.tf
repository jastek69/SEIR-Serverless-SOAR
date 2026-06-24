# CloudWatch WAF logging configuration. This file defines the resources for logging WAF events to either CloudWatch Logs or Kinesis Firehose, based on the value of the `waf_log_destination` variable.
# The logging configuration is associated with the `taaops_cf_waf01` Web ACL, and includes redaction of sensitive fields such as the `Authorization` and `Cookie` headers.

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group 

data "aws_caller_identity" "current" {}

data "aws_cloudwatch_log_group" "taaops_cw_waf_log_group" {
  count    = var.waf_log_destination == "cloudwatch" ? 1 : 0
  provider = aws.us-west-2

  name = "aws-waf-logs-${var.project_name}-cloudfront-waf"
}


# CloudWatch Log Group for WAF logging
data "aws_iam_policy_document" "taaops_cf_waf_log_policy" {
  count   = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # Include :* so log stream operations are covered
    resources = ["${data.aws_cloudwatch_log_group.taaops_cw_waf_log_group[0].arn}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["${aws_wafv2_web_acl.taaops_cf_waf01.arn}:*"]
    }
  }
}

# CloudWatch Log Resource Policy for WAF logging
resource "aws_cloudwatch_log_resource_policy" "waf_logs_resource_policy" {
  count           = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0
  policy_name     = "WAF-CloudWatch-Logs-Policy-${var.project_name}"
  policy_document = data.aws_iam_policy_document.taaops_cf_waf_log_policy[0].json
}

# Cloudwatch logging path
resource "aws_wafv2_web_acl_logging_configuration" "taaops_cf_waf_logging" {
  count    = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0
  provider = aws.us-west-2

  resource_arn = aws_wafv2_web_acl.taaops_cf_waf01.arn
  # Use one destination type per logging configuration. CloudWatch uses a CloudWatch Logs resource policy,
  # while S3 uses an S3 bucket policy in the separate S3 logging configuration below.
  log_destination_configs = [
    data.aws_cloudwatch_log_group.taaops_cw_waf_log_group[0].arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  depends_on = [aws_wafv2_web_acl.taaops_cf_waf01]
}


# S3 Bucket for logs
resource "aws_s3_bucket" "aws-waf-logs-cf-dest" {
  count    = var.waf_log_destination == "s3" ? 1 : 0
  provider = aws.us-west-2

  bucket        = "aws-waf-logs-${var.project_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# S3 WAF logging path
# Safety Gate: Count is used to conditionally create the policy only when S3 is the log destination.
# (count = 1): If WAF is enabled AND the destination is set to "s3", create this resource - when both conditions are true (WAF enabled AND destination set to "s3"), count=1
# (count = 0): Otherwise skip it
# WAF log destination is set in tfvars with the variable `waf_log_destination` set to "s3" or "cloudwatch" or "firehose"
resource "aws_wafv2_web_acl_logging_configuration" "taaops_cf_waf_logging_s3" {
  count    = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0
  provider = aws.us-west-2

  resource_arn = aws_wafv2_web_acl.taaops_cf_waf01.arn
  log_destination_configs = [
    aws_s3_bucket.aws-waf-logs-cf-dest[0].arn
  ]
}


# WAF Bucket Policy to allow WAF to write logs to S3
resource "aws_s3_bucket_policy" "aws-waf-logs-cf-dest-policy" {
  count    = var.waf_log_destination == "s3" ? 1 : 0
  provider = aws.us-west-2

  bucket = aws_s3_bucket.aws-waf-logs-cf-dest[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AWSLogDeliveryWrite20150319"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.aws-waf-logs-cf-dest[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = [data.aws_caller_identity.current.account_id]
          }
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.aws-waf-logs-cf-dest[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = [data.aws_caller_identity.current.account_id]
          }
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
          }
        }
      }
    ]
  })
}


# DynamoDB WAF Lambda Policy
resource "aws_iam_policy" "waf_lambda_dynamodb_policy" {
  count    = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0
  provider = aws.us-west-2

  name        = "${var.project_name}-waf-lambda-dynamodb-policy"
  description = "Policy for WAF Lambda to access DynamoDB for Bedrock analyzer"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${data.aws_cloudwatch_log_group.taaops_cw_waf_log_group[0].name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.dynamoDb_waf_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = aws_ssm_parameter.waf_bedrock_analyzer_prompt.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "waf_lambda_dynamodb_policy_attachment" {
  count      = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0  #Gating check to ensure the policy is only attached when WAF is enabled and the log destination is CloudWatch
  provider   = aws.us-west-2
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.waf_lambda_dynamodb_policy[count.index].arn
}


### KINESIS IMPLEMENTATION
/* FIREHOSE Configuration for WAF logging. 
# Note: If using Firehose for WAF logging, the `aws_wafv2_web_acl_logging_configuration` resource must be recreated to properly associate with the new Firehose delivery stream.
# This is because the logging configuration cannot be updated in place to change the log destination type.
# The `create_before_destroy` lifecycle setting ensures that the new logging configuration is created before the old one is destroyed, preventing any gaps in logging.


resource "aws_s3_bucket" "taaops_cf_waf_firehose_dest" {
  count    = var.waf_log_destination == "firehose" ? 1 : 0
  provider = aws.us-west-2

  bucket = "${var.project_name}-cf-waf-firehose-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "taaops_cf_waf_firehose_pab" {
  count    = var.waf_log_destination == "firehose" ? 1 : 0
  provider = aws.us-west-2

  bucket                  = aws_s3_bucket.taaops_cf_waf_firehose_dest[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "taaops_cf_waf_firehose_role" {
  count    = var.waf_log_destination == "firehose" ? 1 : 0
  provider = aws.us-west-2
  name     = "${var.project_name}-cf-waf-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "taaops_cf_waf_firehose_policy" {
  count    = var.waf_log_destination == "firehose" ? 1 : 0
  provider = aws.us-west-2
  name     = "${var.project_name}-cf-waf-firehose-policy"
  role     = aws_iam_role.taaops_cf_waf_firehose_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.taaops_cf_waf_firehose_dest[0].arn,
          "${aws_s3_bucket.taaops_cf_waf_firehose_dest[0].arn}/*"
        ]
      }
    ]
  })
}


# Note: If using Firehose for WAF logging, the `aws_wafv2_web_acl_logging_configuration` resource must be recreated to properly associate with the new Firehose delivery stream. This is because the logging configuration cannot be updated in place to change the log destination type. The `create_before_destroy` lifecycle setting ensures that the new logging configuration is created before the old one is destroyed, preventing any gaps in logging.

resource "aws_kinesis_firehose_delivery_stream" "taaops_cf_waf_firehose" {
  count       = var.waf_log_destination == "firehose" ? 1 : 0
  provider    = aws.us-east-1
  name        = "aws-waf-logs-${var.project_name}-cf-waf-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.taaops_cf_waf_firehose_role[0].arn
    bucket_arn = aws_s3_bucket.taaops_cf_waf_firehose_dest[0].arn
    prefix     = "cf-waf-logs/"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "taaops_cf_waf_logging_firehose" {
  count    = var.enable_waf && var.waf_log_destination == "firehose" ? 1 : 0
  provider = aws.us-east-1

  resource_arn = aws_wafv2_web_acl.taaops_cf_waf01.arn
  log_destination_configs = [
    aws_kinesis_firehose_delivery_stream.taaops_cf_waf_firehose[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.taaops_cf_waf01]
}
*/