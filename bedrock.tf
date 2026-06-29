############################################
# Bedrock Auto Incident Report Pipeline (SNS -> Lambda -> S3)
############################################


# Data source for current AWS account
data "aws_caller_identity" "taaops_self01" {}

module "taaops_translation" {
  source = "./modules/translation"

  region              = var.region
  common_tags         = var.common_tags
  force_destroy       = var.force_destroy
  reports_bucket_name = aws_s3_bucket.taaops_ir_reports_bucket.bucket
  reports_bucket_arn  = aws_s3_bucket.taaops_ir_reports_bucket.arn
  kms_key_arn         = var.translation_kms_key_arn
}

# Package local Lambda source (no console zip needed)
data "archive_file" "taaops_ir_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/ir_reporter/ir_reporter_handler.py"
  output_path = "${path.module}/lambda/ir_reporter.zip"
}

# Explanation: The incident reports archive—Galactus's digital filing cabinet for postmortem artifacts.
resource "aws_s3_bucket" "taaops_ir_reports_bucket" {
  bucket        = "${var.project_name}-taaops-incident-reports-${data.aws_caller_identity.taaops_self01.account_id}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-incident-reports"
    Purpose     = "Incident report storage"
    Environment = "production"
    Region      = "taaops"
  })
}

resource "aws_sns_topic" "taaops_ir_reports_topic" {
  name = "${var.project_name}-taaops-ir-reports-topic"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-ir-reports"
    Purpose     = "Incident report notifications"
    Environment = "production"
    Region      = "taaops"
  })
}

# Dedicated SNS topic to trigger the reporter Lambda (prevents recursion)
resource "aws_sns_topic" "taaops_ir_trigger_topic" {
  name = "${var.project_name}-taaops-ir-trigger-topic"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-ir-trigger"
    Purpose     = "Lambda trigger for incident reports"
    Environment = "production"
    Region      = "taaops"
  })
}

# Explanation: This role is the Herald's brain—Lambda assumes it to collect evidence and call Bedrock.
resource "aws_iam_role" "taaops_ir_lambda_role" {
  name = "${var.project_name}-taaops-ir-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-ir-lambda-role"
    Purpose     = "Incident report Lambda execution role"
    Environment = "production"
    Region      = "taaops"
  })
}

# Explanation: Galactus grants the minimum needed—logs, S3, SSM, Secrets, CloudWatch, and Bedrock invoke.
resource "aws_iam_policy" "taaops_ir_lambda_policy" {
  name = "${var.project_name}-taaops-ir-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs Insights queries
      {
        Effect = "Allow",
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      # CloudWatch alarm/metrics read
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ],
        Resource = "*"
      },
      # Parameter Store
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.taaops_self01.account_id}:parameter/lab/db/*"
      },
      # Secrets Manager reserved for a future database-backed configuration.
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "secretsmanager:GetSecretValue",
      #     "secretsmanager:DescribeSecret"
      #   ],
      #   Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.taaops_self01.account_id}:secret:${var.project_name}/rds/mysql*"
      # },
      # S3 report write
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.taaops_ir_reports_bucket.arn,
          "${aws_s3_bucket.taaops_ir_reports_bucket.arn}/*"
        ]
      },
      # Translation buckets access for integration
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          module.taaops_translation.input_bucket_arn,
          "${module.taaops_translation.input_bucket_arn}/*"
        ]
      },
      # SNS notify "Report Ready"
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.taaops_ir_reports_topic.arn
      },
      # Bedrock invoke
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "*"
      },
      # SSM Automation document execution
      {
        Effect = "Allow",
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeAutomationExecutions",
          "ssm:DescribeAutomationStepExecutions"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.taaops_self01.account_id}:automation-definition/${var.project_name}-taaops-incident-report:*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.taaops_self01.account_id}:automation-execution/*"
        ]
      },
      # KMS access for encrypted resources
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = var.translation_kms_key_arn
      },
      # Auto Scaling Group permissions for SSM automation
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:StartInstanceRefresh"
        ],
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-ir-lambda-policy"
    Purpose     = "Incident report Lambda permissions"
    Environment = "production"
    Region      = "taaops"
  })
}

# Explanation: Attach the policy — Galactus equips the Lambda like a proper Herald engineer.
resource "aws_iam_role_policy_attachment" "taaops_ir_lambda_attach" {
  role       = aws_iam_role.taaops_ir_lambda_role.name
  policy_arn = aws_iam_policy.taaops_ir_lambda_policy.arn
}

# Explanation: Basic Lambda logging—because even Heralds need diaries.
resource "aws_iam_role_policy_attachment" "taaops_ir_lambda_basiclogs" {
  role       = aws_iam_role.taaops_ir_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Explanation: The Lambda itself — Galactus's incident scribe that writes your postmortem while you fight fires, like a true Herald.
resource "aws_lambda_function" "taaops_ir_lambda" {
  function_name = "${var.project_name}-taaops-ir-reporter"
  role          = aws_iam_role.taaops_ir_lambda_role.arn
  handler       = "ir_reporter_handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  filename         = data.archive_file.taaops_ir_lambda_zip.output_path
  source_code_hash = data.archive_file.taaops_ir_lambda_zip.output_base64sha256

  environment {
    variables = {
      REPORT_BUCKET      = aws_s3_bucket.taaops_ir_reports_bucket.bucket          # S3 for JSON + Markdown reports
      TRANSLATION_BUCKET = module.taaops_translation.input_bucket_name            # Translation integration
      APP_LOG_GROUP      = "/aws/ec2/rdsapp"                                      # App log group (CloudWatch Agent default)
      WAF_LOG_GROUP      = "aws-waf-logs-${var.project_name}-taaops-regional-waf" # Regional WAF log group
      # SECRET_ID         = "${var.project_name}/rds/mysql"                       # Reserved for a future database-backed configuration
      SSM_PARAM_PATH      = "/lab/db/"                                   # Parameter Store path for DB config
      BEDROCK_MODEL_ID    = var.bedrock_claude_model_id                  # Bedrock model ID (optional)
      SNS_TOPIC_ARN       = aws_sns_topic.taaops_ir_reports_topic.arn    # SNS topic for "Report Ready"
      AUTOMATION_DOC_NAME = "${var.project_name}-taaops-incident-report" # SSM automation document
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-taaops-ir-reporter"
    Purpose     = "Automated incident report generation"
    Environment = "production"
    Region      = "Oregon"
  })
}

# Explanation: This subscription wires the trigger topic to the reporter Lambda.
resource "aws_sns_topic_subscription" "taaops_ir_lambda_sub" {
  topic_arn = aws_sns_topic.taaops_ir_trigger_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.taaops_ir_lambda.arn
}

# Explanation: Allow SNS to invoke Lambda — Galactus authorizes the distress beacon to wake the Herald
resource "aws_lambda_permission" "taaops_allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.taaops_ir_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.taaops_ir_trigger_topic.arn
}

# CloudWatch alarms should publish to the dedicated trigger SNS topic.
# The SNS -> Lambda subscription and permission are defined above.


# SOAR

# Prompt template for Bedrock (could be stored in SSM or Secrets Manager in a real implementation)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagent_prompt

resource "aws_bedrockagent_prompt" "soar" {
  name            = "${var.project_name}-taaops-soar-prompt"
  description     = "Prompt template for SOAR playbook generation"
  default_variant = "soar-default"

  variant {
    name     = "soar-default"
    model_id = var.bedrock_claude_model_id

    inference_configuration {
      text {
        temperature = 0.8
        max_tokens  = var.soar_max_tokens
      }
    }

    template_type = "TEXT"

    template_configuration {
      text {
        text = <<EOT
You are a SOC analyst assistant specialized in SOAR playbook generation.

Analyze this security event:
- User authenticated successfully
- JWT token issued
- Token never used within 15 minutes

Provide your analysis in the following structure:

1. Severity assessment with justification.
2. Possible explanations ranked by likelihood.
3. Recommended analyst actions.
4. Short executive summary.
5. Recommended remediation explanations.
6. Possible code snippets and walkthroughs for remediation.
EOT
      }
    }
  }

  variant {
    name     = "soar-experimental"
    model_id = var.bedrock_claude_model_id

    inference_configuration {
      text {
        temperature = 0.8
        max_tokens  = 2000
      }
    }

    template_type = "TEXT"

    template_configuration {
      text {
        text = <<EOT
You are a SOC analyst assistant specialized in complex SOAR investigation and remediation planning.

Analyze the provided security event and produce:
- Severity and rationale
- Likely causes ranked by confidence
- Analyst investigation steps
- Remediation actions
- Automation ideas and code snippets
EOT
      }
    }
  }
}



# WAF Lambda
data "archive_file" "waf_bedrock_analyzer" {
  type        = "zip"
  source_file = "./src/waf_bedrock_analyzer.py"
  output_path = "./lambda/waf_bedrock_analyzer.zip"
}

resource "aws_lambda_function" "waf_bedrock_analyzer" {
  filename      = data.archive_file.waf_bedrock_analyzer.output_path
  function_name = "waf_bedrock_analyzer_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "waf_bedrock_analyzer.lambda_handler"
  code_sha256   = data.archive_file.waf_bedrock_analyzer.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE                         = aws_dynamodb_table.dynamoDb_waf_events.name
      WAF_LOG_GROUP                          = "aws-waf-logs-${var.project_name}-cloudfront-waf"
      BEDROCK_MODEL_ID                       = var.bedrock_waf_model_id
      WAF_BEDROCK_ANALYZER_PROMPT_PARAM_NAME = aws_ssm_parameter.waf_bedrock_analyzer_prompt.name
      WAF_BEDROCK_ANALYZER_MAX_OUTPUT_TOKENS = "300"
      WAF_BEDROCK_ANALYZER_TEMPERATURE       = "0.3"
      WAF_BEDROCK_ANALYZER_RISK_FOCUS        = "all"
      WAF_BEDROCK_ANALYZER_GENERATE_ON_EMPTY = "true"
    }
  }
}




# Parameter Store for sensitive prompts
# At runtime this is called by the Lambda (unused_token_detector.py) to retrieve the prompt template for Bedrock LLM analysis.
# Flow: Lambda -> SSM Parameter Store -> Bedrock Agent Prompt text -> Bedrock Call
resource "aws_ssm_parameter" "soar_prompt" {
  name  = "/bedrock/soar-prompt"
  type  = "String"
  value = file("${path.module}/prompts/soar-prompt.txt")
}

resource "aws_ssm_parameter" "waf_bedrock_analyzer_prompt" {
  name  = "/bedrock/waf-bedrock-analyzer-prompt"
  type  = "String"
  value = file("${path.module}/prompts/waf-bedrock-analyzer-prompt.txt")
}
