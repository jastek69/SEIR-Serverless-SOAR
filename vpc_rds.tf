# =============================================================================
# Phase 11 — Serverless intake with RDS MySQL in a dedicated VPC (us-west-2)
#
# Client -> API Gateway (HTTP API, POST /intake) -> VPC Lambda -> RDS MySQL
#
# Design decisions:
# - Dedicated VPC (not the default VPC) with two private subnets across AZs.
#   No IGW/NAT: the intake Lambda's only external dependency is Secrets
#   Manager, reached through a VPC interface endpoint.
# - RDS is never publicly accessible; port 3306 admits ONLY the Lambda SG.
# - DB credentials live exclusively in Secrets Manager (username, password,
#   host, port, dbname) — never in code, env vars, or state-adjacent files
#   beyond what Terraform itself must track.
# - The audit_events table is bootstrapped by the Lambda itself
#   (CREATE TABLE IF NOT EXISTS) because the private DB has no bastion.
# =============================================================================

# --- Network -----------------------------------------------------------------

resource "aws_vpc" "rds_intake_vpc" {
  cidr_block           = "10.11.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true # required for the Secrets Manager endpoint's private DNS

  tags = merge(var.common_tags, {
    Name      = "${var.project}-intake-vpc"
    Component = "phase11-intake"
  })
}

resource "aws_subnet" "intake_private" {
  for_each = {
    a = { cidr = "10.11.1.0/24", az = "${var.region}a" }
    b = { cidr = "10.11.2.0/24", az = "${var.region}b" }
  }

  vpc_id            = aws_vpc.rds_intake_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name      = "${var.project}-intake-private-${each.key}"
    Component = "phase11-intake"
  })
}

# --- Security groups ---------------------------------------------------------

resource "aws_security_group" "intake_lambda" {
  name        = "${var.project}-intake-lambda-sg"
  description = "Intake Lambda ENIs"
  vpc_id      = aws_vpc.rds_intake_vpc.id

  egress {
    description = "Lambda to RDS and VPC endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_security_group" "intake_rds" {
  name        = "${var.project}-intake-rds-sg"
  description = "RDS MySQL - 3306 only from the intake Lambda SG"
  vpc_id      = aws_vpc.rds_intake_vpc.id

  ingress {
    description     = "MySQL from intake Lambda only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.intake_lambda.id]
  }

  # No egress rules: RDS never initiates outbound connections.

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_security_group" "intake_vpce" {
  name        = "${var.project}-intake-vpce-sg"
  description = "Secrets Manager interface endpoint - 443 from the intake Lambda SG"
  vpc_id      = aws_vpc.rds_intake_vpc.id

  ingress {
    description     = "HTTPS from intake Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.intake_lambda.id]
  }

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

# Private path to Secrets Manager — the VPC has no internet route on purpose.
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.rds_intake_vpc.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.intake_private : s.id]
  security_group_ids  = [aws_security_group.intake_vpce.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${var.project}-secretsmanager-vpce"
    Component = "phase11-intake"
  })
}

# --- RDS MySQL ---------------------------------------------------------------

resource "aws_db_subnet_group" "intake" {
  name       = "${var.project}-intake-dbsubnet"
  subnet_ids = [for s in aws_subnet.intake_private : s.id]

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "random_password" "intake_db" {
  length  = 24
  special = false # mirrors get-random-password --exclude-punctuation
}

resource "aws_db_instance" "intake" {
  identifier     = "${var.project}-intake-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.rds_db_name
  username = var.rds_db_username
  password = random_password.intake_db.result

  db_subnet_group_name   = aws_db_subnet_group.intake.name
  vpc_security_group_ids = [aws_security_group.intake_rds.id]

  publicly_accessible     = false
  backup_retention_period = 0 # lab instance; no automated backups
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

# --- Secrets Manager ---------------------------------------------------------

resource "aws_secretsmanager_secret" "intake_db" {
  name                    = "${var.project}-intake-db-secret"
  description             = "RDS MySQL credentials for the Phase 11 intake Lambda"
  recovery_window_in_days = 0 # lab: allow immediate re-create on destroy/apply cycles

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_secretsmanager_secret_version" "intake_db" {
  secret_id = aws_secretsmanager_secret.intake_db.id
  secret_string = jsonencode({
    username = var.rds_db_username
    password = random_password.intake_db.result
    host     = aws_db_instance.intake.address
    port     = 3306
    dbname   = var.rds_db_name
  })
}

# --- Lambda IAM --------------------------------------------------------------

resource "aws_iam_role" "intake_lambda" {
  name = "${var.project}-intake-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_iam_role_policy_attachment" "intake_lambda_logs" {
  role       = aws_iam_role.intake_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "intake_lambda_vpc" {
  role       = aws_iam_role.intake_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "intake_lambda_secret" {
  name = "${var.project}-intake-read-db-secret"
  role = aws_iam_role.intake_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = aws_secretsmanager_secret.intake_db.arn
    }]
  })
}

# --- Lambda packaging (pymysql is not in the managed runtime) ----------------

resource "terraform_data" "intake_lambda_build" {
  triggers_replace = {
    source       = filesha256("${path.module}/src/rds_lambda_function.py")
    dependencies = "pymysql==1.1.1"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      rm -rf "${path.module}/build/rds_intake"
      mkdir -p "${path.module}/build/rds_intake"
      python -m pip install --quiet --no-compile \
        --platform manylinux2014_x86_64 --implementation cp --python-version 3.12 --only-binary=:all: \
        --target "${path.module}/build/rds_intake" pymysql==1.1.1
      cp "${path.module}/src/rds_lambda_function.py" "${path.module}/build/rds_intake/"
    EOT
  }
}

data "archive_file" "intake_lambda" {
  depends_on  = [terraform_data.intake_lambda_build]
  type        = "zip"
  source_dir  = "${path.module}/build/rds_intake"
  output_path = "${path.module}/lambda/rds_intake.zip"
}

# --- Lambda function ---------------------------------------------------------

resource "aws_lambda_function" "rds_intake" {
  filename         = data.archive_file.intake_lambda.output_path
  source_code_hash = data.archive_file.intake_lambda.output_base64sha256
  function_name    = "${var.project}-intake-mysql"
  role             = aws_iam_role.intake_lambda.arn
  handler          = "rds_lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 10
  memory_size      = 256

  vpc_config {
    subnet_ids         = [for s in aws_subnet.intake_private : s.id]
    security_group_ids = [aws_security_group.intake_lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN      = aws_secretsmanager_secret.intake_db.arn
      DB_NAME            = var.rds_db_name
      DB_CONNECT_TIMEOUT = "5"
    }
  }

  # ENI-attached Lambdas can't be created until the endpoint/SG plumbing exists.
  depends_on = [
    aws_iam_role_policy_attachment.intake_lambda_vpc,
    aws_vpc_endpoint.secretsmanager,
  ]

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_cloudwatch_log_group" "rds_intake" {
  name              = "/aws/lambda/${aws_lambda_function.rds_intake.function_name}"
  retention_in_days = 60
}

# --- HTTP API (API Gateway v2): POST /intake ---------------------------------

resource "aws_apigatewayv2_api" "intake" {
  name          = "${var.project}-intake-api-mysql"
  protocol_type = "HTTP"

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_apigatewayv2_integration" "intake" {
  api_id                 = aws_apigatewayv2_api.intake.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.rds_intake.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "intake_post" {
  api_id    = aws_apigatewayv2_api.intake.id
  route_key = "POST /intake"
  target    = "integrations/${aws_apigatewayv2_integration.intake.id}"
}

resource "aws_apigatewayv2_stage" "intake_prod" {
  api_id      = aws_apigatewayv2_api.intake.id
  name        = "prod"
  auto_deploy = true

  tags = merge(var.common_tags, { Component = "phase11-intake" })
}

resource "aws_lambda_permission" "intake_apigw" {
  statement_id  = "AllowIntakeHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_intake.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.intake.execution_arn}/*/*/intake"
}

# --- Outputs -----------------------------------------------------------------

output "intake_invoke_url" {
  description = "POST target for the Phase 11 intake flow"
  value       = "${aws_apigatewayv2_stage.intake_prod.invoke_url}/intake"
}

output "intake_rds_endpoint" {
  description = "Private RDS MySQL endpoint (reachable only from inside the intake VPC)"
  value       = aws_db_instance.intake.address
}

output "intake_db_secret_arn" {
  description = "Secrets Manager secret holding the intake DB credentials"
  value       = aws_secretsmanager_secret.intake_db.arn
}
