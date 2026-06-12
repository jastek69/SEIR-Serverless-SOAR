# Immutable bucket - long-term audit evidence with Object lock for immutability for compliance and security



resource "aws_s3_bucket" "immutable_audit_bucket" {
  bucket = "${var.project}-immutable-record-${random_string.random.result}"
  force_destroy = false
  object_lock_enabled = false  # Set to true if you want to enable object lock
  
 
}


resource "aws_s3_bucket_server_side_encryption_configuration" "immutable_audit_bucket_encryption" {
  bucket = aws_s3_bucket.immutable_audit_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

 
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket_cors_configuration" "cors_configuration" {
  bucket = aws_s3_bucket.immutable_audit_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
 


resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.immutable_audit_bucket.id
  target_bucket = aws_s3_bucket.immutable_audit_bucket.id
  target_prefix = "logs/"
}


# Bucket Notification (Trigger)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.immutable_audit_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.python_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.immutable_audit_bucket.arn
}





# Hash
resource "aws_apigatewayv2_api" "rest_api" {
  name = "${var.project}-api"
  protocol_type = "HTTP"
}

resource "aws_sqs_queue" "rest_api_queue" {
  name = "${var.project}-queue"
}

data "archive_file" "process_hash" {
  type        = "zip"
  source_file = "./src/node_lambda.js"
  output_path = "./lambda/process_hash.zip"
}

resource "aws_lambda_function" "process_hash" {
  function_name = "${var.project}-process-orders"
  handler       = "node_lambda.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.process_hash.output_path
  source_code_hash = data.archive_file.process_hash.output_base64sha256
}


# Cloudfront Bucket
data "aws_iam_policy_document" "cloudfront_logs" {
    statement {
        sid    = "AllowCloudFrontLogs"
        effect = "Allow"
        principals {
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }
        actions   = ["s3:PutObject"]
        resources = ["${aws_s3_bucket.immutable_audit_bucket.arn}/*"]
    }
}


# WAF Logging bucket see waf_logging.tf for configuration of bucket and policy to allow WAF to write logs to S3