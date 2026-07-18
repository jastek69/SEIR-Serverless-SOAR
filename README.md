☁️ Class 7 Armageddon - Brotherhood of Evil jerMutants - Wolfpack

![shallnotpass.jpg](/images/RBAC-shallnotpass.jpg "sebekgo logo")

![Static Badge](https://img.shields.io/badge/IaC-Terraform-orange)![lambda](https://img.shields.io/badge/Serverless-lambda-orange)![{Cognito}](https://img.shields.io/badge/RBAC%2FJWT-Cognito-blue)![API Gateway](https://img.shields.io/badge/RestAPIs-API%20Gateway-red)![Static Badge](https://img.shields.io/badge/Real%20Time%20Logging-AWS%20WAFV2-red)![Static Badge](https://img.shields.io/badge/AutoIR-BedRock-green)![Static Badge](https://img.shields.io/badge/Observability-CloudWatch%26BedRock-green)![Static Badge](https://img.shields.io/badge/SOAR-Bedrock-green)

##### This repository contains Serverless solutions with Lambda, S3, IAM permissions, API Gateway WAF and Cognito for security, Bedrock and Cloudwatch for Observability, Bedrock for SOAR

---

## ✍️ Authors & Acknowledgments

**Credit: TheoRec** for the orginal starting code base

[jastek69:](https://github.com/jastek69): main repo

-----

# Supporting Documentation

Refer to the `/docs` folder for detailed explanations and walkthrough instructions:

- rbac-test.md for how to configure and run this repo using the bash and python scripts:
  - `mfa_bootstrap.py` - Detailed instructions for using the mfa_boostrap.py to configure Cognito and prepare for testing
    - `rbac_test.sh` - for testing the configuration and generating logs and Bedrock SOAR
- docs/dynamodb-lambda.md - detailed information on DynamoDB token/session tracking with Lambda integration
- cognito_walkthru.md - Cognito AWS console walkthru
- jwt.md - Cognito OAuth JWT wtih API Gateway details
- lambda-walkthru - lambda AWS console instructions
- WAF.md -  WAFV2 confiuration details

# Lambda Invocation Outline

The current Terraform configuration wires Lambda functions to these runtime trigger paths:

- `python_lambda_function`
  - Called by API Gateway on `GET /PythonResource` after Cognito authorization and scope checks.
  - Called by S3 when a new object is created in the immutable audit bucket.
- `node_lambda_function`
  - Called by API Gateway on `GET /NodeResource` after Cognito authorization and scope checks.
- `unused_token_detector_function`
  - Called every 5 minutes by EventBridge Scheduler.
- `immediate_revoke_66_function`
  - Called when a CloudWatch alarm changes to `ALARM` through an EventBridge rule.
- `${var.project_name}-taaops-ir-reporter`
  - Called by SNS when a message is published to the incident trigger topic.
- `${local.name_prefix}-processor`
  - Called by S3 when a new object is created in the translation input bucket.
- `get_token_function`, `python_rbac_function`, `verify_groups_function`, `update_token_function`, `revoke_token_function`, `${var.project}-process-orders`, `waf_bedrock_analyzer_function`
  - Deployed in Terraform, but not automatically wired to an AWS event source in the current configuration.
  - Some of these are used by direct CLI or test-script invocation.

## Lambda Trigger Table

| Lambda function | When it is called | Trigger source | Terraform or repo reference |
|---|---|---|---|
| `python_lambda_function` | When `GET /PythonResource` is invoked with a valid Cognito token and required scope; also when a new object is created in the immutable audit bucket | API Gateway, S3 bucket notification | `api.tf`, `s3.tf` |
| `node_lambda_function` | When `GET /NodeResource` is invoked with a valid Cognito token and required scope | API Gateway | `api.tf` |
| `unused_token_detector_function` | Every 5 minutes | EventBridge Scheduler | `eventbridge.tf`, `lambda.tf` |
| `immediate_revoke_66_function` | Whenever a CloudWatch alarm enters the `ALARM` state | EventBridge rule on CloudWatch alarm state changes | `eventbridge.tf`, `lambda.tf` |
| `${var.project_name}-taaops-ir-reporter` | When SNS publishes to the dedicated incident trigger topic | SNS subscription | `bedrock.tf` |
| `${local.name_prefix}-processor` | When a new object is created in the translation module input bucket | S3 bucket notification | `modules/translation/main.tf` |
| `get_token_function` | No automatic trigger defined in Terraform | Manual or direct invoke | `lambda.tf` |
| `python_rbac_function` | No automatic trigger defined in Terraform | Manual or direct invoke | `lambda.tf` |
| `verify_groups_function` | No automatic trigger defined in Terraform | Manual or direct invoke | `lambda.tf` |
| `update_token_function` | No AWS event trigger defined; used directly in repo test flow to mark tokens as used | Direct CLI or test invocation | `lambda.tf`, `docs/rbac-test.md`, `scripts/rbac_test.sh` |
| `revoke_token_function` | No automatic trigger defined in Terraform | Manual or direct invoke | `lambda.tf` |
| `${var.project}-process-orders` | No trigger wiring is present | Not currently called by Terraform-managed events | `s3.tf` |
| `waf_bedrock_analyzer_function` | No trigger wiring is present | Not currently called by Terraform-managed events | `bedrock.tf` |
| `${var.project}-intake-mysql` | When `POST /intake` is invoked on the Phase 11 HTTP API | API Gateway v2 (HTTP API) | `vpc_rds.tf` |
| `waf-threat-correlation-agent` | Every 60 minutes | EventBridge Scheduler | `soar_agents.tf` |
| `soar-response-agent` | When a `WAF Threat Finding Created` event with severity MEDIUM/HIGH/CRITICAL is published on the default event bus | EventBridge rules (`soar-finding-medium-high`, `soar-finding-critical`) | `soar_agents.tf` |
| `executive-dashboard-agent` | No automatic trigger defined in Terraform | Manual or direct invoke (test event: `{"report_period_hours": 24}`) | `soar_agents.tf` |

# Phase 11 — Serverless Intake with RDS MySQL (VPC)

Client → API Gateway (HTTP API, `POST /intake`) → VPC-attached Lambda → RDS MySQL (private).

All resources live in `vpc_rds.tf`, in `us-west-2`:

- Dedicated VPC `rds_intake_vpc` (`10.11.0.0/16`) with two private subnets across AZs. There is **no IGW or NAT**; the intake Lambda reaches Secrets Manager through a VPC interface endpoint and everything else it needs (RDS) is in-VPC.
- RDS MySQL 8.0 (`db.t3.micro`, 20 GB, encrypted) with `publicly_accessible = false`. Port 3306 admits **only** the Lambda security group — no CIDR-based ingress.
- DB credentials (username, password, host, port, dbname) live in a Secrets Manager secret; the password is generated by `random_password` and never appears in code or env vars. The Lambda reads the secret at runtime via `DB_SECRET_ARN`.
- `src/rds_lambda_function.py` is packaged with `pymysql` at apply time (`terraform_data` build step runs `pip install --target`; requires `bash` and `python` on PATH during `terraform apply`). The Lambda bootstraps the `audit_events` table with `CREATE TABLE IF NOT EXISTS` on first connection, because the private DB has no bastion for manual DDL.
- Verification gates: `scripts/gate_11a_*.sh`, `scripts/run_all_gates_11a.sh`; incident-response drill in `scripts/gate_11b_incident.sh`. Full lab narrative in `docs/Phase11and12.md`.

# Phase 12 — SOAR Agent Pipeline

```
AWS WAF → CloudWatch Logs → waf_bedrock_analyzer_function → DynamoDB waf-events
        → waf-threat-correlation-agent (hourly)
        → DynamoDB waf-correlation-findings
        → EventBridge custom event (source seir.waf.correlation,
          detail-type "WAF Threat Finding Created")
        → soar-response-agent
            ├── retrieves the authoritative finding from DynamoDB
            ├── selects a deterministic playbook by severity
            ├── Bedrock analyst/manager summaries (informational only)
            ├── conditional-put incident INC-<finding_id> into security-incidents
            ├── SNS notification to soar-response-notifications
            └── marks the finding RESPONSE_COMPLETED
```

Defined in `soar_agents.tf` plus two new tables in `dynamo_db.tf` (`waf-correlation-findings`, `security-incidents`):

- **EventBridge routing**: MEDIUM/HIGH findings target only `soar-response-agent`; CRITICAL findings additionally fan out to the `critical-alert` SNS topic. The correlation agent publishes the event itself (`events:PutEvents` on the default bus) after saving the finding — the event carries routing data only (`finding_id`, `severity`, `risk_score`); the agent re-reads the full record from DynamoDB.
- **Idempotency**: incident IDs are deterministic (`INC-<finding_id>`) with a conditional put, so EventBridge redelivery cannot duplicate incidents; the finding status update is likewise condition-guarded on `OPEN`.
- **executive-dashboard-agent** (manual invoke, 1024 MB / 120 s) scans all three tables and writes synchronized PDF + JSON executive reports to the `…-executive-reports-<account>` bucket under `executive-reports/YYYY/MM/DD/{pdf,json}/`. `reportlab==4.4.3` is packaged at apply time the same way as pymysql.
- Each agent has its own least-privilege IAM role (not the shared `lambda_execution_role`).

## MCP Server — SOAR agents control plane (local prototype)

`mcp-server/mcp_server.py` is a FastMCP **stdio** server that exposes the Phase 12 agents to Claude Code as tools. It is a control plane *beside* the pipeline — the EventBridge-driven flow keeps running autonomously; the server only adds analyst-facing reads (DynamoDB/S3, read-only) and explicit agent invocations (`lambda:InvokeFunction`).

Tools: `list_findings`, `get_finding`, `list_incidents`, `get_incident`, `get_executive_report` (presigned URL) · `run_correlation`, `rerun_soar_response`, `generate_executive_report`.

Setup (uses your local AWS credentials; the deployed stack must exist):

```bash
pip install -r mcp-server/requirements.txt
# .mcp.json registers it at project scope automatically, or manually:
claude mcp add soar-agents -- python mcp-server/mcp_server.py
```

Full reference — tool table, env-var overrides, and the promotion path to a Lambda-hosted HTTP server behind a Cognito JWT authorizer (including the future `approve_containment` admin tool) — in `docs/MCP.md`.

# Architecture — Root Files, Modules, and Parameter Store

Three different wiring mechanisms hold this repo (and its companion
workstation repo) together. They solve different problems and fail
differently — don't conflate them. In particular: **modules are NOT built
around Parameter Store.** Modules are a Terraform code-organization boundary;
Parameter Store is a runtime data boundary.

## Layer 1 — inside the root: direct references

The root files (`cognito.tf`, `api.tf`, `waf.tf`, `lambda.tf`,
`dynamo_db.tf`, `bedrock.tf`, …) reference each other by resource address —
e.g. `api.tf`'s authorizer points at `aws_cognito_user_pool.cognito_rbac_pool.arn`
directly. One state file, one plan; Terraform orders everything from these
references, and a bad reference fails loudly at `terraform plan`.

## Layer 2 — root ↔ module: variables in, outputs out

A module (`modules/translation`, `modules/jobs`) is a folder of `.tf` files
with a deliberate interface. It cannot see the root's resources at all — it
only knows what the root passes in, and the root only gets back what the
module outputs:

```
root's PythonAPI id ──────────► var.rest_api_id ───┐
root's Cognito authorizer id ─► var.authorizer_id ──┤→ modules/jobs builds its
job-type maps ────────────────► var.queue_visibility_timeouts ─┘ routes/queues/table
                                                       │
root's PythonDeployment ◄── module.jobs.deployment_trigger_hash
```

That last arrow matters: the module can't force the root's REST API to
redeploy (the deployment resource belongs to the root), so it exports a hash
of its routes and the root folds that into its own deployment `triggers`.
Still one state file, one `terraform apply` — the module is purely
encapsulation, like a class with a constructor signature.

## Layer 3 — across states and at runtime: Parameter Store

SSM appears only where Terraform references are impossible:

- **Cross-root handshake.** The workstation repo (stability_ai) cannot
  reference `module.jobs.queue_urls` — different repo, different state. So
  the jobs module *publishes* `/jobs/queue-urls` and `/jobs/table-name`, and
  the workstation's `bootstrap.sh.tpl` reads them at boot. Symmetrically,
  the workstation publishes `/stability-matrix/bucket`, which the Bedrock
  failure reporter reads at runtime.
- **Runtime configuration.** `/bedrock/soar-prompt`,
  `/bedrock/jobs-failure-prompt`, etc. aren't wiring at all — they're
  editable content, in SSM precisely so they can change without touching
  Terraform or code (`ignore_changes = [value]` protects console edits).

## The structural picture

```
SEIR root (state: global/lambda-terraform.tfstate)
├── Platform layer (root files) — shared by everything:
│   Cognito pool/groups/resource-server, PythonAPI + NodeAPI + authorizers,
│   WAF + logging, token-lifecycle Lambdas + DynamoDB tables, SOAR/Bedrock,
│   EventBridge, S3 audit buckets
├── module "taaops_translation" — self-contained: own buckets, Lambda, IAM;
│   interface = bucket names/ARNs in, bucket names out
└── module "jobs" — self-contained: queues+DLQs, jobs table, 4 Lambdas,
    2 scoped IAM roles, EventBridge rules;
    interface = API attachment points + job-type maps in,
    trigger hash + queue/table identifiers out
    └── publishes /jobs/* to SSM ← aimed at the OTHER repo, not at this root
```

Mental model: **root = the platform** (identity, ingress, protection —
things every subsystem shares); **modules = subsystems that rent space on
the platform** through a narrow constructor; **SSM = the published API
between independently-deployed stacks**.

## Why it's shaped this way

- Adding a job type touches only the two maps in the root's `jobs.tf` — the
  module fans one entry out into a queue, DLQ, reporter wiring, and a
  refreshed `/jobs/queue-urls` automatically.
- Phase 3 (containerized workers on AWS Batch) changes nothing in
  `modules/jobs`: the job contract + SSM parameters are the interface, and a
  Batch worker reads the same queue today's EC2 worker does.
- If jobs ever needs its own repo/state, the module is pre-shaped for
  extraction: its only tethers to this root are the variables it's passed,
  and external consumers already go through SSM rather than state references.

## Caveat — the layers fail differently

A bad Layer-2 reference fails loudly at `terraform plan`. A Layer-3 mismatch
— e.g. renaming the jobs module's `name_prefix` while the workstation's IAM
policy still matches `taaops-jobs-*` — fails silently until runtime
(`AccessDenied` in the worker log). That's the price of decoupled states;
the convention-coupled spots are flagged in code comments and in the
workstation repo's `README_worker-nodes.md` troubleshooting table.

# Terraform Templates – Reusable Skeleton

1.1. Base module pattern

Instructions

“Each lambda project = one Terraform root with a modules/serverless_app module.
Fork this skeleton and wire the specific resources for each project"

Root main.tf:
Root variables.tf:
Root outputs.tf:

1.2. Example module for a typical lab (Lab 1 / Lab 2 structure)

Sample:
modules/serverless_app/sample_main.tf:

You can add/remove S3/SQS/SNS/EventBridge rules per lab but reuse this structure.
Remember: “clone Lab 1’s TF, then modify resources per lab design.”

## Lambda runtimes

[refer to documentation for latest version](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
Lambda is 3.14
Java 24.x

## IAM Roles and Policies

[AWS Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html)
Roles: for bigger organizations
policies: smaller in scale

IAM Policy workflow example:
IAM = user or service
IAM role = titled position bound to IAM user/service
IAM policy = what the IAM role can access, and what actions the IAM role can take

e.g.
IAM = "Aaron" aka @Aaron McDonald
IAM role = traveler_SEA assigned to IAM user "Aaron"
IAM policy = granting passport (multi-organization) access for "traveler_SEA"  to organizations attached to account "SE Asia"

Attach roles
policies of Role

Role
principal - IAM identity
action
attach: ARN

IAM Identity
Role
Policy attachment

Lambda - role resource and bucket policy
attach

S3 bucket policy attach to lambda

Policy for:

***API Gateway -service***
NOTE: could also use a Role for API gateway - use if utilizing several functions (policies) - not as secure
give permission to run lambda - resource based policy on lambda
principal of Policy
action: to invoke lambda
attach: ARN oflambda function

Role of Lambda

Summary
POLICY consists of:
principal: API GW
Action: Invoke
ARN: lambda function x

Code signing
[Code Signing](https://www.hashicorp.com/en/blog/announcing-support-for-aws-lambda-code-signing-in-the-terraform-aws-provider)

Parenting
/company
/c

# Part 1 - Event-Driven Order Processing Pipeline

This builds a small “orders” backend where:
    - API calls create orders
    - Orders are written to Aurora
    - An asynchronous pipeline handles payment, inventory, and notification via events/queues.

## Core services

    * API Gateway (REST or HTTP API)
    * Lambda (order creation, payment processor, notification worker)
    * Aurora Serverless v2 (orders + line items)
    * EventBridge (OrderCreated, OrderPaid events)
    * SQS (work queue for payment processing + DLQ)
    * SNS (customer notification topic)
    * S3 (optional: for order receipts/invoices)

## Results

    * POST /orders writes a row into Aurora and emits an OrderCreated event to EventBridge.
    * A Lambda subscribed via EventBridge picks up OrderCreated, writes a “pending payment” record, and pushes a message to SQS.
    * A separate Lambda (triggered by SQS) “processes payment” (mock) and:
        - updates the Aurora order row to PAID
        - publishes OrderPaid to EventBridge
        - publishes a notification to an SNS topic
    * Test script (curl/Postman) shows full flow from order creation → paid → notification.
    * Terraform (or scripts) can tear down and recreate the whole stack.

# Part 2 - Serverless Order System

    ## Architecture:
        * API Gateway REST/HTTP → Lambda (validation, enrichment) → SQS
        * Worker Lambda pulls from SQS, writes to Aurora orders table
    
    ## Lab correctness signals:
        * Orders with invalid fields are rejected at API layer
        * SQS DLQ configured and demonstrably catches poison messages
        * Aurora schema supports indexing by order_id / customer_id

# IMAGE CONVERSION

## Supported File Types

Current behavior: this Lambda copies objects from source to destination (no resize yet), so file type is not restricted by the function logic.

- Commonly tested: JPG/JPEG and PNG
- Also works for copy-only flow: GIF, WEBP, PDF, and other object types

If you later add real resize/transformation logic, supported file types will depend on the image library used (for example, Sharp supports JPG/JPEG, PNG, WEBP, GIF, AVIF, and TIFF).

## Testing

## AWS Pre-Checks

Verify Region in CLI is set properly
`aws configure get region`

Set Global Default Region:
`aws configure set region us-west-2`

Per command use:
`--region us-west-2`
`aws logs tail '/aws/lambda/image_processor' --region us-west-2 --since 10m --follow`

1. Start CloudWatch log tail:
     `MSYS_NO_PATHCONV=1 aws logs tail '/aws/lambda/image_processor' --region us-west-2 --since 10m --follow`

## Windows Git Bash AWS CLI Cheat Sheet

If you use Git Bash on Windows, slash-prefixed AWS values (like `/aws/lambda/...`) may be rewritten into Windows paths. This causes errors such as:
`Value 'C:/Program Files/Git/aws/lambda/...' failed to satisfy constraint...`

### Fast fixes

1. One command only:
     `MSYS_NO_PATHCONV=1 aws <service> <command> ...`

2. Entire terminal session:
     `export MSYS_NO_PATHCONV=1`

3. Quote slash-prefixed values:
     `'/aws/lambda/image_processor'`

### CloudWatch Logs

- Tail Lambda logs:
    `MSYS_NO_PATHCONV=1 aws logs tail '/aws/lambda/image_processor' --region us-west-2 --since 10m --follow`

- List Lambda log groups:
    `MSYS_NO_PATHCONV=1 aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/' --region us-west-2 --query "logGroups[].logGroupName" --output table`



## CloudWatch

Lambda log group and what to click once you’re in CloudWatch so you can follow new invocations live.
Use this direct Console path (already scoped to your region/log group):

<https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/%2Faws%2Flambda%2Fimage_processor>

CloudWatch >> Logs >> Log Management >> enter Log Group: /aws/lambda/image_processor
Open the log group /aws/lambda/image_processor
Sort by Last Event Time so newest streams are on top.
Click the latest log stream (name like 2026/04/23/[$LATEST]...).
Use the search box for:
Copy successful.
ERROR
AccessDenied

 live-ish view in Console:

Go to CloudWatch > Logs Insights
Select log group /aws/lambda/image_processor
Run:
fields @timestamp, @message
| sort @timestamp desc
| limit 100

# Reference Links

[Creating Lambda Function](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)
[Hashicorp Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#handler-1)
[AWS CLI create-function](https://docs.aws.amazon.com/cli/latest/reference/lambda/create-function.html)
[Python Handler](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
Handler naming conventions

The function handler name defined at the time that you create a Lambda function is derived from:

The name of the file in which the Lambda handler function is located.

The name of the Python handler function.

In the example above, if the file is named lambda_function.py, the handler would be specified as lambda_function.lambda_handler. This is the default handler name given to functions you create using the Lambda console.

If you create a function in the console using a different file name or function handler name, you must edit the default handler name.

To change the function handler name (console)
Open the Functions page of the Lambda console and choose your function.

Choose the Code tab.

Scroll down to the Runtime settings pane and choose Edit.

In Handler, enter the new name for your function handler.

Choose Save.

[AWS tutorial - Lambda and Rest API](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway-tutorial.html)

## Invoke URL

The Invoke URL for an Amazon API Gateway in Terraform is an attribute exported by deployment or stage resources that provides the base endpoint for accessing your API. To get the Invoke URL for a standard REST API, use the invoke_url attribute from the aws_api_gateway_stage resource. Or for newer HTTP or WebSocket APIs, the URL is retrieved from the aws_apigatewayv2_stage resource.

```hcl
output "api_url" {
  value = aws_api_gateway_stage.example.invoke_url
}
```

```hcl
output "http_api_url" {
  value = aws_apigatewayv2_stage.example.invoke_url
}
```

# Construct the URL manually

To construct the URL manually or for specific resources, you can concatenate the API ID and Region:
    - Base URL: `Format: https://{restapi_id}.execute-api.{region}.amazonaws.com/{stage_name}`
    - Full Resource Path: To point to a specific endpoint, append the resource path: `${aws_api_gateway_stage.example.invoke_url}/items`

To Run:
curl "<https://f3sdn1pb3a.execute-api.us-west-2.amazonaws.com/prod/PythonResource>"

Python: curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/PythonResource?name=Chewbacca"

Node: curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/NodeResource?name=Malgus"

## Invoke with CLI

`
aws lambda invoke \
  --function-name arn:aws:lambda:us-west-2:015195098145:function:python_lambda_function \
  --payload '{}' \
  response.json
  `

## CloudWatch Logs

`MSYS_NO_PATHCONV=1 aws logs tail '/aws/lambda/python_lambda_function' --region us-west-2 --since 15m`

locals for lambda permissions - for scalable deployments

``` python
locals {
  api_lambda_permissions = {
    python = {
      function_name = aws_lambda_function.python_lambda.function_name
      source_arn    = "${aws_api_gateway_rest_api.PythonAPI.execution_arn}/*/*"
    }
    node = {
      function_name = aws_lambda_function.node_lambda.function_name
      source_arn    = "${aws_api_gateway_rest_api.NodeAPI.execution_arn}/*/*"
    }
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  for_each      = local.api_lambda_permissions
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = each.value.source_arn
}
```

# WAF Implementation for Serverless

AI cannot determine specifications
You must determine the Law

## Test

This stack exposes two REST API resources:

- Python: `$(terraform output -raw api_python_invoke_url)/PythonResource`
- Node: `$(terraform output -raw api_node_invoke_url)/NodeResource`

Use the Terraform outputs plus the exact resource paths shown above. The working paths in this deployment are `PythonResource` and `NodeResource`.

## WAF Test Modes

Use `terraform.tfvars` to switch the WAF rate-based rule behavior:

- Blocking mode: `waf_rate_limit_action = "block"`
- Observation mode for API Gateway throttle testing: `waf_rate_limit_action = "count"`

Apply after changing modes:

```bash
terraform apply
```

## Malicious Traffic Test

Normal requests:

```bash
curl "$(terraform output -raw api_python_invoke_url)/PythonResource?name=Chewbacca"
curl "$(terraform output -raw api_node_invoke_url)/NodeResource?name=Malgus"
```

Suspicious input that should be blocked by WAF:

```bash
curl "$(terraform output -raw api_python_invoke_url)/PythonResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
curl "$(terraform output -raw api_node_invoke_url)/NodeResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
```

Expected result:

- Normal requests return application output.
- Suspicious input returns HTTP `403` with `{"message":"Forbidden"}`.

## WAF Rate-Limit Test

Keep WAF in `block` mode for this test.

Burst traffic past the `100 requests / 300 seconds` limit and print each request so you can see when responses flip to `403`:

```bash
base="$(terraform output -raw api_python_invoke_url)/PythonResource?name=rate-test"
ts="$(date +%s)"

for i in {1..250}; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "${base}&n=$i&ts=$ts")
    echo "$(date +%H:%M:%S) burst $i -> HTTP $code"
done
```

If the burst finishes before the rule starts enforcing, poll until it does:

```bash
for i in {1..36}; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "${base}&check=$i&ts=$ts")
    echo "$(date +%H:%M:%S) check $i -> HTTP $code"
    [[ "$code" == "403" ]] && echo "WAF block confirmed" && break
    sleep 5
done
```

Expected result:

- Early responses can still be `200`.
- Once the rate-based rule catches up, requests return HTTP `403`.

## API Gateway Protection - Throttling Test

1 API Gateway with 2 endpoints

secure access, MCP security, SQL injections - data sanitation for AI (in and out), AI and guardrails

To test API Gateway throttling specifically, keep WAF in `count` mode so WAF does not block first.

Prerequisites:

- Both REST APIs must use `endpoint_configuration { types = ["REGIONAL"] }` in `api.tf`.
- Temporarily lower `variables.tf` defaults to:
    `api_throttle_rate_limit = 1`
    `api_throttle_burst_limit = 2`

Apply the test settings:

```bash
terraform apply
```

Visible sequential test:

```bash
url="$(terraform output -raw api_python_invoke_url)/PythonResource?name=throttle-test"

for i in {1..20}; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "$url")
    echo "Request $i -> HTTP $code"
done
```

Visible parallel test:

```bash
url="$(terraform output -raw api_python_invoke_url)/PythonResource?name=throttle-test"

for i in {1..200}; do
    (
        code=$(curl -sS -o /dev/null -w "%{http_code}" "$url")
        echo "Request $i -> HTTP $code"
    ) &
done
wait
```

Summary count test:

```bash
url="$(terraform output -raw api_python_invoke_url)/PythonResource?name=throttle-test"

for i in {1..200}; do
    (
        code=$(curl -sS -o /dev/null -w "%{http_code}" "$url")
        echo "$code"
    ) &
done
wait | sort | uniq -c
```

Expected result:

- The first 1-2 requests usually return `200`.
- Most following requests return `429`.
- Occasional `200` responses can reappear as the token bucket refills.

Restore production settings after the test:

- In `variables.tf`, set `api_throttle_rate_limit = 25` and `api_throttle_burst_limit = 50`.
- In `terraform.tfvars`, set `waf_rate_limit_action = "block"`.
- Run `terraform apply` again.

## Verify WAF Logs / Metrics Go to: WAF → Your Web ACL → Overview

    - Look at: Allowed requests Blocked requests

# S3 Logging

[S3 Logging](https://docs.aws.amazon.com/waf/latest/developerguide/logging-s3.html)
[WAF ACL Logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration)

### Quick Verification with CLI

1. Get the WAF logs bucket from Terraform output:

```bash
terraform output waf_logs_bucket
```

1. List top-level prefixes in the bucket:

```bash
aws s3 ls s3://<waf-logs-bucket>/
```

1. Check for recently written objects:

```bash
aws s3api list-objects-v2 \
    --bucket <waf-logs-bucket> \
    --max-items 20 \
    --query "Contents[].{Key:Key,LastModified:LastModified,Size:Size}" \
    --output table
```

1. Filter only the AWS log prefix:

```bash
aws s3api list-objects-v2 \
    --bucket <waf-logs-bucket> \
    --prefix AWSLogs/ \
    --max-items 20 \
    --query "Contents[].Key" \
    --output table
```

1. Confirm logging is attached to your Web ACL:

```bash
aws wafv2 list-web-acls --scope REGIONAL --region us-west-2
aws wafv2 get-logging-configuration --resource-arn <web-acl-arn> --region us-west-2
```

1. Optional quick traffic test, then re-check S3:

```bash
for i in {1..20}; do
    curl -s "$(terraform output -raw api_python_invoke_url)/PythonResource?name=test" > /dev/null
done
```

### Console Checks

1. WAF Console: Web ACL -> Logging and metrics (verify destination and request counts).
2. S3 Console: Open the WAF logs bucket and verify objects under AWSLogs/.
3. CloudWatch Metrics: Check WAF allowed/blocked request trends.

### Common Gotchas

1. Bucket name must start with `aws-waf-logs-`.
2. Bucket policy should allow `delivery.logs.amazonaws.com` with `aws:SourceAccount` and `aws:SourceArn` conditions.
3. WAF logging must be enabled on the exact Web ACL ARN you are testing.

# Cognito

Amazon Cognito handles user authentication and authorization for your web and mobile apps. With user pools, you can easily and securely add sign-up and sign-in functionality to your apps. With identity pools (federated identities), your apps can get temporary credentials that grant users access to specific AWS resources, whether the users are anonymous or are signed in.
[Cognito](https://docs.aws.amazon.com/cognito/)
<https://github.com/BalericaAI/lambda/blob/main/lessond_cognito/readme.md>

[Cognito REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html)

Cognito — What It Is, Purpose, and Why It Matters

What is Cognito?
In simple terms: ---> “Cognito answers one question: Who are you?”

Amazon Cognito is AWS’s managed identity service.

It handles:

    User authentication (login, passwords, tokens)
    User management (accounts, groups)
    Token generation (JWTs) for APIs

[Cognito IAM](https://aws.amazon.com/pm/cognito/?trk=36e1404e-1051-48b6-9dd0-51db40b9c756&sc_channel=ps&ef_id=CjwKCAjwqubPBhBOEiwAzgZX2nhsEiOHEJQVaqlAYrksnh6lOFWjvE4VxyRyQ3izPOoltgjOxDh6mBoCOngQAvD_BwE:G:s&s_kwcid=AL!4422!3!795794010901!p!!g!!cognito!23527793912!187898877050&gad_campaignid=23527793912&gbraid=0AAAAADjHtp8JXL4yKgorV0cpJGxLu-Nuy&gclid=CjwKCAjwqubPBhBOEiwAzgZX2nhsEiOHEJQVaqlAYrksnh6lOFWjvE4VxyRyQ3izPOoltgjOxDh6mBoCOngQAvD_BwE)

Purpose of Cognito in This Lab

So far, your API:

    Accepts requests from anyone
    Has WAF to filter bad traffic
    But does not know who is calling

Cognito adds:

    Identity verification
    Controlled access
    Authenticated API usage

Updated System Flow: Client → WAF → API Gateway (Cognito Auth) → Lambda → Logs

NOTE!!!!---> If authentication fails, Lambda is never executed

Why you Want to Use Cognito

Because in the real world:

        Unlike Keisha, APIs are never open
        Loyal Systems must know:
            who is calling
            what they are allowed to do
        Security is not optional—it’s foundational

Without Cognito:

        Any Pookie can hit your Keisha API. 
        No accountability, just welfare
        No identity context, who knows who was there? Who's the daddy?

With Cognito:
        Every request has an identity
        Think of this like, no ring---> No hit.
        Access can be controlled
        Behavior can be customized per user

Steps:

As an alternative to using IAM roles and policies or Lambda authorizers (formerly known as custom authorizers), you can use an Amazon Cognito user pool to control who can access your API in Amazon API Gateway.

To use an Amazon Cognito user pool with your API, you must first create an authorizer of the COGNITO_USER_POOLS type and then configure an API method to use that authorizer. After the API is deployed, the client must first sign the user in to the user pool, obtain an identity or access token for the user, and then call the API method with one of the tokens, which are typically set to the request's Authorization header. The API call succeeds only if the required token is supplied and the supplied token is valid, otherwise, the client isn't authorized to make the call because the client did not have credentials that could be authorized.

The identity token is used to authorize API calls based on identity claims of the signed-in user. The access token is used to authorize API calls based on the custom scopes of specified access-protected resources. For more information, see Using Tokens with User Pools and Resource Server and Custom Scopes.

To create and configure an Amazon Cognito user pool for your API, you perform the following tasks:

Use the Amazon Cognito console, CLI/SDK, or API to create a user pool—or use one that's owned by another AWS account.

Use the API Gateway console, CLI/SDK, or API to create an API Gateway authorizer with the chosen user pool.

Use the API Gateway console, CLI/SDK, or API to enable the authorizer on selected API methods.

To call any API methods with a user pool enabled, your API clients perform the following tasks:

Use the Amazon Cognito CLI/SDK or API to sign a user in to the chosen user pool, and obtain an identity token or access token. To learn more about using the SDKs, see Code examples for Amazon Cognito using AWS SDKs.

Use a client-specific framework to call the deployed API Gateway API and supply the appropriate token in the Authorization header.

Workflow: Client → WAF → API Gateway (Cognito Auth) → Lambda → Logs

1. Create User Pool
    - name of lambda
    - mail, ph, and username
    - enforce MFA
    - select attributes
    - create user directory
    - view sign-in page
    - selct user Pool and configure MFA with Authenticator apps, email, SMS for lab - in an office use auth and passkey

Configure SMS - give the Role
role name - SMS
password policy

User Pools > new user pool and use new under Appl Clients > view login page
Create a new user

ZionTheo
Armag3ddon!69

Add a passkey
User Pool > Password List >> Option for choice based sign in > edit MFA in blue box
Select user verification with passkey - to enable
edit for choice base sign in - to add

Cognito ClickOps Lab — User Authentication (No Federation)
We will do Federation in SEIR-II

Objective---> “We are not building a login page. We are building an identity system that issues tokens.”

Students will:

    Create a User Pool
    Enable login with:
        username
        email
        phone number
    Enforce MFA
    Create and authenticate a user
    Use the JWT to call your REST API

Updated Flow: Client → WAF → API Gateway (Cognito Authorizer) → Lambda

Task 1 — Create Cognito User Pool
  Navigation
  
    AWS Console → Cognito
    Click User Pools
    Click Create user pool

Step-by-Step Configuration

1. Sign-in Options

Select: “We allow multiple identity inputs. Real systems don’t force one.”

        ✔ Username
        ✔ Email
        ✔ Phone number

2. Password Policy

Keep default or slightly stronger:

        Min 8 characters
        Numbers + symbols

3. MFA Configuration---> “MFA is not optional in real systems.”

Set: Required MFA

        MFA Types:
        ✔ SMS
        ✔ TOTP (Authenticator app)

4. User Account Recovery

        Enable:
        ✔ Email
        ✔ Phone

5. Attributes

Set required:

        ✔ email
        ✔ phone_number

6. App Client

Create one:

Name: chewbacca-client

Disable: ----> ❌ Client secret

Why? Client secret complicates API usage. We keep it simple.

Click Create

Task 2 — Create a User

Inside User Pool:

        Go to Users
        Click Create user

Fill:

        Username: lizzo1
        Email: student1@lizzo.com
        Phone: +1XXXXXXXXXX

Set password manually: --->  Permanent password
“We are skipping email verification to move faster. We will return to it later"

Task 3 — Enable MFA for User

Inside User:
        Click user
        Set MFA:

        ✔ Enable MFA
        ✔ Choose:

SMS OR Authenticator app

If TOTP:
    Scan QR code with:
        Google Authenticator
        or Microsoft Authenticator

Task 4 — Get JWT Token (CLI Method)
This isn't easy. Let's go slow.

Use AWS CLI:

        aws cognito-idp initiate-auth \
          --auth-flow USER_PASSWORD_AUTH \
          --client-id <CLIENT_ID> \
          --auth-parameters USERNAME=student1,PASSWORD=YourPassword

If MFA is required → challenge returned

Then run:

        aws cognito-idp respond-to-auth-challenge \
          --client-id <CLIENT_ID> \
          --challenge-name SMS_MFA \
          --challenge-responses USERNAME=student1,SMS_MFA_CODE=123456 \
          --session <SESSION>

Result:

You get:

        {
          "AuthenticationResult": {
            "IdToken": "...",
            "AccessToken": "...",
            "RefreshToken": "..."
          }
        }

Use: AccessToken

Task 5 — Create API Gateway Authorizer

Go to API Gateway (REST API)--> Authorizers → Create New ---> Type: Cognito --->

Configure:

        Name:chewbacca-authorizer
        Cognito User Pool: → Select your pool
        Token Source: Authorization

Task 6 — Attach Authorizer to Methods

For /python and For /node:

    Method Request --> Authorization: Cognito Authorizer

Task 7 — Deploy API (Again!)

👉 REST API requires redeploy
Actions → Deploy API → prod

Task 8 — Test

Without Token --->

        curl https://<api>/prod/python 

 --> 401 Unauthorized

With Token -->  

        curl https://<api>/prod/python \
          -H "Authorization: <ACCESS_TOKEN>" 

→ 200 OK

Task 9 — Verify Behavior

1. Did Lambda run when no token?
2. Where was request blocked?
3. What changed in event?

Final Explanation

    What Cognito does?
    What API Gateway does?
    What MFA adds?
    Why AccessToken matters?

To get token place this in the CLI with correct username and actual password or sms MFA code:
aws cognito-idp initiate-auth \
      --auth-flow USER_PASSWORD_AUTH \
      --client-id <CLIENT_ID> \
      --auth-parameters USERNAME=student1,PASSWORD=YourPassword

aws cognito-idp respond-to-auth-challenge \
      --client-id <CLIENT_ID> \
      --challenge-name SMS_MFA \
      --challenge-responses USERNAME=student1,SMS_MFA_CODE=123456 \
      --session <SESSION>

Error message: obtain secret hash
[Auth Challenge](https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html)
<https://stackoverflow.com/questions/44244441/how-to-create-a-secret-hash-for-aws-cognito-using-boto3>

[Resolve Auth](https://repost.aws/knowledge-center/cognito-unable-to-verify-secret-hash)

```
import sys, hmac, hashlib, base64

# Unpack command line arguments
username, app_client_id, key = sys.argv[1:4]

# Create message and key bytes
message, key = (username + app_client_id).encode('utf-8'), key.encode('utf-8')

# Calculate secret hash
secret_hash = base64.b64encode(hmac.new(key, message, digestmod=hashlib.sha256).digest()).decode()

print(f"Secret Hash for user '{username}': {secret_hash}")
```

to run auth.pu script:
`python3 secret_hash.py username app_client_id app_client_secret`

Add your secret hash value as a SECRET_HASH parameter in the query string parameters of the API call.

Example InitiateAuth API call that includes a SECRET_HASH parameter:

`aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --auth-parameters USERNAME=username,PASSWORD=password,SECRET_HASH=secret_hash --client-id example_client-id`

only cop the hash

`export SECRET="<key>"
`echo $SECRET

see auth flows in console > Authentication Flows: go to edit allow user password auth  ARTA, AUA, AUPA

# Cognito JWT Flow Summary

reference links:
<https://repost.aws/knowledge-center/cognito-unable-to-verify-secret-hash>
<https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html>

1. Create/run a Python script to generate the Cognito `SECRET_HASH`

- Obtain `SECRET_HASH` by running the Python script: python auth.py ziontheo 7im6sn4tj742m8s7njfr7olqga ri6fb0nihm6p3p05k36g32318o74olvh695ht7455o64728g8t5

1. Generate the `SECRET_HASH` by running the python script using:

- Cognito username
- Cognito app client ID
- Cognito app client secret value

1. Call `initiate-auth` to start authentication. This initiates an authorization request and returns a session when MFA is required.

Inputs:

- `USERNAME`
- `PASSWORD`
- `SECRET_HASH`

Output with MFA enabled:

- `ChallengeName`
- `Session`

1. Call `respond-to-auth-challenge` to respond to the MFA session challenge.

Inputs:

- `USERNAME`
- `SOFTWARE_TOKEN_MFA_CODE`
- `SECRET_HASH`
- `Session` from `initiate-auth`

NOTE: the challenge name is `SOFTWARE_TOKEN_MFA`.

Output:

- `AuthenticationResult`

Example:

```
set +H
MFA_CODE='123456'
SESSION='PASTE_SESSION_VALUE_HERE'

aws cognito-idp respond-to-auth-challenge \
  --region us-east-1 \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --challenge-name SOFTWARE_TOKEN_MFA \
  --session "$SESSION" \
  --challenge-responses "USERNAME=ziontheo,SOFTWARE_TOKEN_MFA_CODE=$MFA_CODE,SECRET_HASH=$SECRET_HASH" \
  --output json
```

1. Retrieve JWTs from `AuthenticationResult`.
NOTE: Respond to the MFA challenge immediately because the `Session` value expires quickly.

Output returns tokens:

1. `AccessToken`
2. `RefreshToken`
3. `IdToken`

NOTE on Passwords: ! in a password
In Bash ! can mean “expand something from command history.”
 set +H should be run before commands that include !.

Solutions:
Run `set +H` first, then store the password in a single-quoted variable. The single quotes protect the password assignment, and `set +H` protects later commands from Bash history expansion.

Step 1: use `set +H` which tells Bash to treat ! as a normal character and not a history shortcut

Step 2: Use single ' ' and set password as VAR PASSWORD

Example:

```
set +H

PASSWORD='Armag3dd0n!69'
SECRET_HASH='NnewiFWnsu52sBfNCuSdTW/VyyjBIpJB9UepJwV40sY='

aws cognito-idp initiate-auth \
  --region us-east-1 \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --auth-parameters "USERNAME=ziontheo,PASSWORD=$PASSWORD,SECRET_HASH=$SECRET_HASH" \
  --output json
```

# TEAR DOWN

Delete the Cognito user pool in AWS Cognito console.

IMPORTANT: Charges may apply for Cognito usage

# WAFV2 Notes

### Rule Management Models

| Model | How rules are managed | Terraform behavior | Best fit |
|---|---|---|---|
| Inline rules in `aws_wafv2_web_acl` | Rules are declared in `rule {}` blocks inside the Web ACL resource | Terraform treats the Web ACL and its rules as a single desired state | Single repo/team owns all WAF rules |
| External rule resources (`aws_wafv2_web_acl_rule` / `aws_wafv2_web_acl_rule_group_association`) | Rules are attached by separate resources | Rules can be managed independently from the base ACL resource | Shared ownership, separate modules/states, staged rollouts |

### Why Drift Happens

If you define rules inline in `aws_wafv2_web_acl` and also add rules using separate rule resources, Terraform sees differences on every plan.
The ACL resource expects its own `rule` list to be authoritative, while external resources are changing that same list.

### Required Lifecycle Setting for Mixed or External Rule Management

When rules are managed outside the main ACL resource, add:

```hcl
resource "aws_wafv2_web_acl" "taaops_cf_waf01" {
    # ...name, scope, default_action, visibility_config...

    lifecycle {
        ignore_changes = [rule]
    }
}
```

This prevents Terraform from trying to "correct" externally-managed rules and avoids perpetual configuration drift.

### Decision Table

| Question | Recommendation |
|---|---|
| One team/repo controls all rules? | Keep rules inline in `aws_wafv2_web_acl` |
| Multiple teams/states add rules? | Use external rule resources and `ignore_changes = [rule]` |
| Need strict enforcement of only declared rules? | Keep inline management (no external rule resources) |
| Need independent rule lifecycle or delegated ownership? | Use external rule resources + lifecycle ignore on `rule` |

### AWS References

| Topic | Link | When to use |
|---|---|---|
| Web ACL resource (Terraform) | [wafv2_web_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | Define the base ACL and inline `rule {}` blocks in Terraform |
| Web ACL association (Terraform) | [wafv2_web_acl_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | Attach a Web ACL to API Gateway stage, ALB, or other supported resources |
| AWS WAF Developer Guide - Web ACLs | [web-acl](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl.html) | Understand ACL structure, evaluation order, and rule behavior |
| AWS WAF Developer Guide - Rule groups | [waf-rule-groups](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-groups.html) | Design reusable custom or managed rule group strategy |
| AWS WAF API Reference - WebACL | [API_WebACL](https://docs.aws.amazon.com/waf/latest/APIReference/API_WebACL.html) | Validate low-level fields and API semantics when troubleshooting |

```
 Client authenticates with Cognito
        ↓
Client receives JWT token
        ↓
Client calls API with Authorization: Bearer <token>
        ↓
AWS WAF
        ↓
API Gateway Cognito Authorizer
        ↓
Lambda
        ↓
CloudWatch / WAF / API Gateway logs
```

1. Create Cognito User Pool
    - Choose sign-in identifiers: username, email, phone, or some combination.
    - Configure required attributes: email, phone number, etc.
    - Configure MFA: authenticator app/TOTP, SMS, email as needed for the lab.

2. Create App Client
    - Go to User pool -> App integration -> App clients.
    - Create a Single-page application / public client style app client.
    - Make sure there is no client secret.
    - Enable USER_PASSWORD_AUTH if your Python script is using username/password directly.
    - Copy this new Client ID into your script.

3. Create User
    - Create user ZionTheo.
    - Make sure the user has the required email/phone attributes.
    - Confirm the user if needed.
    - Complete first sign-in/setup if Cognito requires password reset or MFA enrollment.

4. API Gateway
    - Create a COGNITO_USER_POOLS authorizer.
    - Point it at the Cognito user pool.
    - Attach the authorizer to the protected API method.
    - Client must call API Gateway with:

    ```
    Authorization: Bearer <Cognito JWT>
    ```

5. WAF
    - Associate WAF Web ACL with API Gateway stage.
    - WAF checks the request before API Gateway authorizer/Lambda processing.

6. Lambda and Logs
    - API Gateway invokes Lambda only after WAF allows the request and Cognito authorizer accepts the token.
    - Check API Gateway execution/access logs, Lambda CloudWatch logs, and WAF logs.

Sources:

Cognito app clients: <https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html>
Cognito MFA: <https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html>
API Gateway Cognito authorizer: <https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html>

## Attach to API Gateway Method and Redeploy

attach the Cognito authorizer to:

```
/PythonResource
  GET
  ```

In the API Gateway console, use the REST API named PythonAPI:

1. Open Resources.
2. Select /PythonResource.
3. Select the GET method.
4. Edit the method request / authorization setting.
5. Change authorization from NONE to your Cognito authorizer.
6. Save.
7. Deploy the API to stage: `prod`
8. Click Deploy

## TOKENS

NOTE: for Rest API

REST API Cognito authorizer used as simple authentication, use the ID token instead.

AWS’s REST API Cognito flow is split this way:

- ID token: accepted for basic REST API Cognito authorizer authentication.
- Access token: use it when the API method has Authorization scopes configured and the token carries an accepted scope.

APIs or Cognito self-service endpoints. (docs.aws.amazon.com)

Cognito tokens:
docs.aws.amazon.com
Token Main question Typical contents In your API test
ID_TOKEN “Who is this user?” Identity claims such as username, email, name, aud, token_use = "id" Works for basic Cognito authentication on a REST API method
ACCESS_TOKEN “What is this user/app allowed to do?” Scopes, groups, client_id, token_use = "access" Works when the REST API method is configured to require accepted authorization scopes

***[ID Token](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-the-id-token.html)***
purpose: authentication / identity
"Who signed in?"

```
username
email
sub
aud
token_use = id
```

The ID token is a JSON Web Token (JWT) that contains claims about the identity of the authenticated user, such as name, email, and phone_number. You can use this identity information inside your application. The ID token can also be used to authenticate users to your resource servers or server applications. You can also use an ID token outside of the application with your web API operations. In those cases, you must verify the signature of the ID token before you can trust any claims inside the ID token. See Verifying JSON web tokens.

```JSON
{
  "token_use": "id",
  "aud": "<app-client-id>",
  "cognito:username": "...",
  "email": "...",
  "sub": "..."
}
```

- Use to prove: This request came from a signed-in Cognito user.
- For an API Gateway REST API Cognito authorizer with no OAuth scopes configured, API Gateway treats the incoming token as an identity token and verifies the user identity against the Cognito user pool.

[Access Token](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-the-access-token.html)
The user pool access token contains claims about the authenticated user, a list of the user's groups, and a list of scopes. The purpose of the access token is to authorize API operations. Your user pool accepts access tokens to authorize user self-service operations. For example, you can use the access token to grant your user access to add, change, or delete user attributes.

With OAuth 2.0 scopes in an access token, derived from the custom scopes that you add to your user pool, you can authorize your user to retrieve information from an API. For example, Amazon API Gateway supports authorization with Amazon Cognito access tokens. You can populate a REST API authorizer with information from your user pool, or use Amazon Cognito as a JSON Web Token (JWT) authorizer for an HTTP API. To generate an access token with custom scopes, you must request it through your user pool public endpoints.

Purpose: authorization / access
"What is this caller allowed to access?"

- API Gateway REST APIs use an access token when you configure method Authorization scopes and the token carries an accepted scope.
- access-token scopes - the mechanism to authorize API access such as a method/path.

authorization-oriented - oauth:

```
scope
groups
client_id
token_use = access
```

```JSON
{
  "token_use": "access",
  "client_id": "<app-client-id>",
  "scope": "aws.cognito.signin.user.admin ...",
  "username": "..."
}
```

Use it when you want to authorize an operation based on permissions/scopes, for example:

```
This caller may read orders.
This caller may create orders.
```

For API Gateway REST APIs specifically:

- An ID token can be passed to a Cognito authorizer for basic authentication.
- An access token is the better fit when you configure Authorization scopes on the API method and the token contains matching scopes. (docs.aws.amazon.com)

```
Use ID_TOKEN to prove Cognito authentication.
Use WAF test input to prove WAF blocking.
```

When adding  a Cognito resource server and scopes such as:

```
lambda-waf/read
lambda-waf/write
```

configure API Gateway method authorization scopes and use the ACCESS_TOKEN for permission-based API authorization.

## SCOPE - OAuth - REST API's

[Integrate REST API with Cognito User Pool](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-enable-cognito-user-pool.html)
With the COGNITO_USER_POOLS authorizer, if the OAuth Scopes option isn't specified, API Gateway treats the supplied token as an identity token and verifies the claimed identity against the one from the user pool. Otherwise, API Gateway treats the supplied token as an access token and verifies the access scopes that are claimed in the token against the authorization scopes declared on the method.

Scope is for Cognito user self-service operations such as querying or updating the signed-in user’s Cognito attributes. It is not a custom API scope for GET /PythonResource.

When the API Gateway REST method is configured for a Cognito user pool authorizer without Authorization scopes. API Gateway treats the token as an ID token. AWS states that when OAuth scopes are not specified for a REST API COGNITO_USER_POOLS authorizer, API Gateway treats the supplied token as an identity token.

Without scope for access token API Gateway treats the token as an ID token. AWS states that when OAuth scopes are not specified for a REST API COGNITO_USER_POOLS authorizer, API Gateway treats the supplied token as an identity token.

To make the access token path work, you would configure authorization scopes:

1. In Cognito, define a resource server and custom scope, for example: `lambda-waf/read`

2. Configure the app client / OAuth flow so Cognito issues an access token containing that scope.

In API Gateway method authorization, require that scope for: `GET /PythonResource`

1. API Gateway will evaluate:

```
ACCESS_TOKEN has required scope -> allow
ACCESS_TOKEN lacks required scope -> deny
```

Testing Paths:

- ID token test = authentication-only REST API setup
- Access token test = scope-based OAuth authorization setup

## Terraform Implementation

Add Authorizer:

```
resource "aws_api_gateway_authorizer" "python_cognito" {
  name        = "python-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.PythonAPI.id

  type          = "COGNITO_USER_POOLS"
  provider_arns = [
    "arn:aws:cognito-idp:us-east-1:015195098145:userpool/<USER_POOL_ID>"
  ]

  identity_source = "method.request.header.Authorization"
}
```

Update method from `authorization = "NONE"` to:

```
resource "aws_api_gateway_method" "PythonMethod" {
  rest_api_id   = aws_api_gateway_rest_api.PythonAPI.id
  resource_id   = aws_api_gateway_resource.PythonResource.id
  http_method   = "GET"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.python_cognito.id
}
```

This tells the API Gateway to:

```
Require a Cognito token from the Authorization header.
Trust this Cognito user pool.
```

Adding Scope:

 want access-token scope authorization, you add scopes to the API method, for example:

 ```
 resource "aws_api_gateway_method" "PythonMethod" {
  rest_api_id   = aws_api_gateway_rest_api.PythonAPI.id
  resource_id   = aws_api_gateway_resource.PythonResource.id
  http_method   = "GET"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.python_cognito.id

  authorization_scopes = [
    "lambda-waf/read"
  ]
}
```

Then configure Cognito to issue an access token containing that scope, usually by defining a Cognito resource server and allowed app-client OAuth scopes. The Terraform method field for that is authorization_scopes; you still do not paste token JSON into Terraform.

The decision is:

- Authentication only: Cognito authorizer + method authorizer, use ID_TOKEN.
- Authorization by permission/scope: add Cognito resource server scopes + method `authorization_scopes`, use `ACCESS_TOKEN`.

### RBAC

RBAC means Role-Based Access Control. The core idea is simple:

```text
User -> Role or Group -> Permissions -> Resource
```

In this lab, Cognito authenticates the user, API Gateway performs the first authorization gate with Cognito OAuth scopes, and Lambda performs the final admin/non-admin RBAC decision from Cognito group claims.

```text
Client -> AWS WAF -> API Gateway Cognito Authorizer + Scope Check -> Lambda RBAC logic -> DynamoDB audit/tracking
```

Authentication and authorization are related, but they are not the same:

| Layer | Responsibility | Current Lab Behavior |
| ----- | -------------- | -------------------- |
| AWS WAF | Filters malicious HTTP traffic before API Gateway | Blocks payloads such as XSS/SQLi when rules match |
| Cognito User Pool | Authenticates the user and issues JWTs | Issues ID/access/refresh tokens after login and MFA |
| API Gateway Cognito Authorizer | Validates the JWT and required OAuth scope | Requires a valid access token with `rbac-api/admin` |
| Lambda | Enforces final RBAC | Reads Cognito claims/groups and allows or denies the request |
| DynamoDB | Tracks token/session metadata | Stores token hash, status, timestamps, revocation/audit metadata |

#### Current Design: Layered Cognito Scope + Lambda RBAC

The current Terraform methods use a Cognito user pool authorizer with `authorization_scopes`:

```hcl
authorization        = "COGNITO_USER_POOLS"
authorizer_id        = aws_api_gateway_authorizer.python_cognito.id
authorization_scopes = ["rbac-api/admin"]
```

That means API Gateway acts as a coarse authorization gate. It verifies that the caller supplied a valid Cognito access token containing the required `rbac-api/admin` scope. After that, Lambda receives the request and performs the final RBAC decision from Cognito group claims.

In this design, API calls are tested with the Cognito access token:

```bash
curl "$API_PY_BASE/PythonResource?name=Norrin" \
  -H "Authorization: $ACCESS_TOKEN"
```

The Lambda handler still reads Cognito claims passed by API Gateway:

```python
claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
groups = claims.get("cognito:groups", "")

if "admin" not in groups:
    return {
        "statusCode": 403,
        "body": '{"message": "Access denied: admin group required"}'
    }
```

This produces the expected lab behavior:

| Caller | Access Token Scope | Group Claim | Result |
| ------ | ------------------ | ----------- | ------ |
| No token | None | None | `401 Unauthorized` |
| Non-admin user | Missing `rbac-api/admin` | `user` | `403 Forbidden` at API Gateway |
| Admin user | Has `rbac-api/admin` | `admin` | `200 OK` |
| Scoped token but non-admin group | Has required scope | Not `admin` | `403 Forbidden` at Lambda |

#### Cognito Resource Server and Scopes

<https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html>

<https://docs.aws.amazon.com/cognito/latest/developerguide/federation-endpoints-oauth-grants.html>
<https://aws.amazon.com/blogs/security/how-to-use-oauth-2-0-in-amazon-cognito-learn-about-the-different-oauth-2-0-grants/>

The Cognito resource server defines API-level scopes:

```hcl
resource "aws_cognito_resource_server" "rbac_api_resource_server" {
  identifier = "rbac-api"
  name       = "RBAC REST API"

  scope {
    scope_name        = "admin"
    scope_description = "Admin access to protected RBAC API methods"
  }

  scope {
    scope_name        = "user"
    scope_description = "User access to protected RBAC API methods"
  }

  user_pool_id = aws_cognito_user_pool.cognito_rbac_pool.id
}
```

The RBAC app client can request both scopes:

```hcl
allowed_oauth_flows_user_pool_client = true
allowed_oauth_flows                  = ["code"]
allowed_oauth_scopes = [
  "openid",
  "email",
  "profile",
  "rbac-api/admin",
  "rbac-api/user"
]
```

The user app client is limited to the user scope:

```hcl
allowed_oauth_scopes = [
  "openid",
  "email",
  "profile",
  "rbac-api/user"
]
```

Both app clients point to the same RBAC user pool. Users are separated by Cognito group membership:

```text
admin.test -> group: admin
user.test  -> group: user
```

This keeps the responsibilities separate:

- API Gateway checks API-level permission with access-token scopes.
- Lambda checks application-level RBAC with Cognito group claims.

#### ID Tokens vs Access Tokens

| Token | Main Purpose | Best Fit |
| ----- | ------------ | -------- |
| ID token | Proves who the signed-in user is | Claim/group based RBAC in Lambda |
| Access token | Proves what the caller is allowed to access | API Gateway scope authorization |

The test playbook exports both token types:

```bash
source Reports/admin_tokens.env
source Reports/non_admin_tokens.env

echo "${#ID_TOKEN}"
echo "${#ACCESS_TOKEN}"
echo "${#NON_ADMIN_ID_TOKEN}"
echo "${#NON_ADMIN_ACCESS_TOKEN}"
```

Manual API tests should use access tokens:

```bash
curl -i "$API_PY_BASE/PythonResource?name=theo" \
  -H "Authorization: $ACCESS_TOKEN"

curl -i "$API_PY_BASE/PythonResource?name=denied" \
  -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
```

AWS documents the split this way: ID tokens authorize API calls based on identity claims, while access tokens authorize API calls based on custom scopes for protected resources.

References:

- API Gateway Cognito authorizers: <https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html>
- Cognito resource servers and scopes: <https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-define-resource-servers.html>
- Cognito access tokens: <https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-the-access-token.html>

#### DynamoDB's Role

DynamoDB does not validate JWTs. Token validation happens through Cognito/API Gateway.

DynamoDB supports the surrounding security workflow:

- Token/session tracking
- Token hash storage instead of raw token storage
- Status values such as `active`, `used`, or `revoked`
- TTL-based cleanup
- Revocation denylist lookups for sensitive operations
- Audit evidence for unused-token detection and SOAR reporting

Example token-tracking fields:

```text
token_id
token_hash
username
status
issued_at
expires_at
last_seen_at
revoked_at
ttl
```

For immediate revocation, use one or more of these controls:

- Short access-token lifetimes
- Refresh-token revocation
- DynamoDB-backed denylist checks for sensitive operations

Detailed implementation notes are in [docs/dynamodb-lambda.md](docs/dynamodb-lambda.md).

### Create: - lessonf walkthru

- DynamoDB
- lambda functions:
  - get_token.py
  - update_token.py
  - unused_token_detector.py - locate unused tokens
  - EventBridge schedule use the unused token for it as the target
  - revoke-token.py - BONUS
- Event Bridge - attach lambda as the target - auto generatate the execution role

[lambda DynamoDB token tracking](https://github.com/aws-samples/serverless-patterns/tree/main/apigw-lambda-dynamodb-terraform)
[apigw + DynamoDB](https://github.com/jastek69/aws-serverless-patterns/blob/main/apigw-dynamodb-terraform/main.tf)

`key_schema`

Table attribute definitions:
data types only: S, N, or B

Key schema definitions:
defines the GSI key structure:

one HASH key
optional one RANGE key
key roles only: HASH or RANGE

How to write data from Lambda

token-tracking item fields:
token_id: string UUID
token_hash: SHA-256 hash of the token
username: caller identity
status: active, used, or revoked
expires_at: Unix epoch seconds
optional extra fields: issued_at_iso, revoked_at_iso, reason
token-revocation item fields:
token_hash: same SHA-256 hash
expires_at: Unix epoch seconds for denylist TTL
revoked_at_iso
reason

***CORE FUNDAMENTAL SECURITY PRINCIPLE:***
refer to [docs/dynamodb-lambda.md](docs/dynamodb-lambda.md)

this is the core of making the token system secure and auditable.

How It Works

When a token is issued, you write one record to tracking table and optionally one record to revocation table only when revoked.
You never store the raw token in DynamoDB, only token_hash.
DynamoDB can support revocation/session-state checks by hashing the incoming token and checking:
revocation table first (fast denylist check)
tracking table status and expiry
expires_at is Unix epoch seconds so DynamoDB TTL can auto-delete old records.
Write Path (Issue Token)
Use this in `easier_get_token.py` or the token-issuing Lambda path.

Generate token_id as UUID.
Hash the token with SHA-256.
Pull username from Cognito claims in API Gateway event.
Set status to active.
Set expires_at to epoch seconds.
Optionally set issued_at_iso for readable audits.
Put item into token-tracking table.
Minimal field map for token-tracking:

token_id
token_hash
username
status
expires_at
issued_at_iso (optional)
Example structure to write:
Item:
token_id = 8f0f...
token_hash = 3f2c...
username = ziontheo
status = active
expires_at = 1780867200
issued_at_iso = 2026-06-07T20:11:10Z

Revoke Path
Use this in update_token.py for revoke/use transitions.

Compute token_hash from presented token.
Update token-tracking status to used or revoked.
Set revoked_at_iso when revoking.
Insert denylist row in token-revocation table with same token_hash and expires_at.
Minimal field map for token-revocation:

token_hash
expires_at
revoked_at_iso
reason
Example structure to write:
Item:
token_hash = 3f2c...
expires_at = 1780867200
revoked_at_iso = 2026-06-07T20:22:10Z
reason = manual_revoke

Optional Read Path (Revocation/Session-State Check)
This logic can live in `python_lambda.py` and `node_lambda.js`, or a shared authorizer Lambda.

Extract token from Authorization header.
Hash token to token_hash.
GetItem on token-revocation by token_hash.
If found and not expired, reject.
Query or Get token-tracking row.
Reject if status is revoked/used or expires_at is in past.
Allow otherwise.
How To Read/Output Values
You usually need these outputs in 3 places: API responses, logs, and Terraform outputs.

API response output:
Return safe fields only, for example:
token_id, status, expires_at, username
Do not return token_hash unless debugging.

CloudWatch logs:
Log structured json with:
request_id, username, token_id, status_before, status_after, reason
This gives audit trace without exposing secrets.

Terraform outputs:
Add table names/arns so Lambdas and operators can discover resources quickly in outputs.tf:

token_tracking_table_name

token_tracking_table_arn

token_revocation_table_name

token_revocation_table_arn

Then read with commands:

terraform output -raw token_tracking_table_name
terraform output -raw token_revocation_table_name
terraform output -json
Epoch Conversion (Important)
TTL needs epoch seconds, not ISO string.
Formula:
expires_at = current_utc_epoch + token_lifetime_seconds

If token life is 15 minutes:
expires_at = now + 900

## Security - Monitoring – logs, metrics, alerting

- Cloudwatch - infrastructure logs, operational logs and alarms
- S3: immutable audit archive: compliance-grade long-term records.
  - long-term audit evidence with Object lock for immutability
  - immutable audit archive: compliance-grade long-term records.

NEVER STORE:
raw access tokens
raw refresh tokens
private wallet keys
JWT signing keys
OAuth client secrets

Example events worth recording:

```
token-tracking
```

Navigation

    DynamoDB
    Create Table

    Table Name: token-tracking
    Partition Key: token_id
    Type:: String
    Capacity Mode: On-demand

Table Purpose

Each token gets tracked:

    {
      "token_id": "abc123",
      "username": "student1",
      "issued_at": "2026-05-19T20:00:00Z",
      "used": false
    }

Phase 2 — Modify get_token.py

Now the script becomes:

    auth utility
    telemetry producer

Add DynamoDB Write---> After successful authentication:
modify your get_token.py

    import uuid
    from datetime import datetime
    
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("token-tracking")
    
    token_id = str(uuid.uuid4())
    
    table.put_item(
        Item={
            "token_id": token_id,
            "username": username,
            "issued_at": datetime.utcnow().isoformat(),
            "used": False
        }
    )

Phase 3 — Mark Token Used

When Lambda receives valid request: Update DynamoDB:
Update your previous Lambda with this: <https://github.com/BalericaAI/lambda/blob/main/lessonf/lambda/update_token.py>

If you want to play with headers then.... Pass token_id as header: -H "x-token-id: abc123"

Phase 4 — Create Detection Lambda

Lambda Name: unused-token-detector

Purpose

Find tokens:

        used = false
        AND
        older than 10 minutes

unused_token_detector.py  Here: <https://github.com/BalericaAI/lambda/blob/main/lessonf/lambda/unused_token_detector.py>

Phase 5 — Event Bridge
[EventBrodge Scheduler](https://docs.aws.amazon.com/lambda/latest/dg/with-eventbridge-scheduler.html)
[EvenBridge Scheduler for lambda](https://serverlessland.com/patterns/eventbridge-schedule-to-lambda-terraform-python)
Go to ---> EventBridge Schedule
Find this!!!!!!  You need to create a schedule, not a rule!!!!

Navigation
        EventBridge
        Rules
        Create Rule

        Name: unused-token-check
        Rule Type: Schedule
        Schedule: rate(5 minutes)
        Target: unused-token-detector Lambda

Phase 6 — Generate Alert

Initially: CloudWatch log only

Example: ALERT: student1 generated token but never used it
ALERT: student2 paid Keisha rent yet didn't smash

Refactor Summary: Lambda >
easier_get_token.py
Flow:

1. API Gateway receives the request with the Cognito JWT.
2. The Cognito authorizer validates the token.
3. API Gateway puts the validated claims into the Lambda event.
4. The Python handler reads those claims and extracts the username.
5. The handler passes that username into the tracking function.

 key separation:

1. handler = reads request/event data
2. tracking function = writes token metadata to DynamoDB

handler gets username fom the Cognito-authenticated event that API Gateway passes in after successful authorization.

handler portion:

``` python
claims = (
    event.get("requestContext", {})
    .get("authorizer", {})
    .get("claims", {})
)
username = claims.get("cognito:username", "unknown_user")
```

While tracking receives plain value:

example:

```python
tracked = track_token_issue(username=username)
```

the handler owns request parsing
the tracking function only handles DynamoDB token-tracking work
the same tracking function can be reused from Lambda, tests, or other code without needing a full API Gateway event
There are really two username sources depending on how the script is being used:

Lambda/API Gateway flow
The username comes from Cognito claims in the incoming event after API Gateway authorizer validation.

Local CLI Cognito login flow
The username comes from the terminal prompt the user entered, not from requestContext claims, because there is no API Gateway event in that case.

There are now two clean usage modes in the same script:

Local user mode (CLI): you run the script directly, it prompts for Username/Password (and MFA if needed), then prints Cognito tokens.
Lambda mode: AWS imports the module and calls the handler when requests arrive. No terminal prompts happen during import, so Lambda starts reliably.

Key Differences Explained

avoids interactive prompts at import time
For a user:
You only see prompts when you intentionally run the script from terminal.
You do not get unexpected blocking prompts in server/runtime environments.
Technically:

Username/password input is moved into a function used only by local execution flow.
Importing the file no longer executes input() or getpass() immediately.
Why this matters:

Prevents hangs/failures in Lambda, tests, CI, and tooling that import modules.
keeps Lambda handler import-safe
For a user:
API calls to Lambda are more stable because cold starts are cleaner.
Fewer startup surprises from module-level side effects.
Technically:

Heavy side effects (prompting, auth flow) are not executed at top level.
Handler path is focused: read event claims, perform tracking action, return response.
Why this matters:

Lambda always imports module first, then invokes handler. Safe imports are critical for predictable serverless behavior.
separates Cognito auth into a dedicated function
For a user:
Login behavior is easier to understand and troubleshoot.
MFA and Cognito challenge handling are in one place.
Technically:

Cognito user/password + challenge response logic lives in a standalone function.
Handler logic and token-tracking logic are decoupled from login flow.
Why this matters:

Better maintainability and reuse.
Easier to unit test each piece independently.
Future updates (new challenge type, different auth flow) affect one focused function.
adds a main entrypoint for local CLI usage only
For a user:
Running the file directly starts the interactive experience.
Importing the file from somewhere else does not start interactive flow.
Technically:

Uses the standard guard pattern so main() runs only when the file is executed as a script.
Why this matters:

One file supports both local dev workflow and Lambda runtime safely, without mixing behaviors.
Practical Before vs After
Before:

Importing the module could immediately prompt for credentials and initialize auth/resources in ways that break non-interactive runtimes.
After:

Import is quiet and safe.
Lambda path is non-interactive.
CLI path is interactive by design.

# CloudWatch

[Alarm events in EventBridge](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-and-eventbridge.html)
[EvenBridge  Scheduler > CloudWatch alarm](https://serverlessland.com/patterns/eventbridge-schedule-to-cloudwatch-alarm-terraform)
[EventBridge custom CloudWatch alarm](https://repost.aws/knowledge-center/eventbridge-custom-cloudwatch-alarm-responses)

[example repo](https://github.com/aws-samples/serverless-patterns/blob/main/eventbridge-cloudwatch-terraform/main.tf)

Scheduler is time-based periodic maintenance.
Alarm rule is event-based security/ops response.

Alarms for:

- token timeout
Alert - token generated but never used

- token revokation
Alert token being misused by bad actor

Direct alarm actions
Set alarm_actions on the alarm (commonly SNS topic ARN).

Event-driven workflow
Create an EventBridge rule for CloudWatch alarm state changes, then attach one or more targets.

New CloudWatch alarms: add alarms.
Rules/targets: only if you want to route alarm events through EventBridge.

# Bedrock

# DynamoDB

# S3

# AWS API Gateway to Amazon EventBridge

# Bedrock SOAR (Security Orchestration, Automation, and Response)

SOAR — Security Orchestration, Automation, and Response

“Cloud systems generate security events constantly. Engineers must know how those events are handled.”

What is SOAR? “SOAR is what happens when security systems stop being passive and start taking action.”

Security Orchestration, Automation, and Response (SOAR) is a security operations approach where systems:

```
detect events
automate investigation steps
perform responses
coordinate multiple security tools together
```

SOAR Changes Model

```
    Event
    → Automated detection
    → Automated enrichment
    → Automated decision
    → Automated response
    → Human escalation if needed
```

Modern environments generate:

    millions of logs
    thousands of alerts
    constant authentication events
    API activity
    cloud telemetry

Humans cannot manually process all of it.

Without automation:

    Alert
    → Human reads it..... Then human watches YouTube a few hours
    → Human investigates..... after a few days
    → Human opens ticket... maybe
    → Human responds.... after payday

SOAR Changes the Model

        Event
        → Automated detection
        → Automated enrichment
        → Automated decision
        → Automated response
        → Human escalation if needed

Key idea: “Humans should handle judgment. Automation should handle repetition.”

SOAR in This Lab---> You are already building the foundation.

Current Workflow

        User logs in
        → Token issued
        → Token unused
        → EventBridge detects behavior
        → Alert generated
        
That is already a lightweight SOAR workflow.

Real-World SOAR Example

Suspicious Login.... from bananaland...

    User authenticates from unusual location
        → SOAR workflow triggered
        → enrich IP reputation
        → check MFA status
        → notify Slack
        → create Jira ticket
        → disable account if high risk

Why Companies Use SOAR

1. Speed --> Automation reacts faster than humans.
2. Consistency --> Playbooks execute the same way every time.
3. Scale--> Security teams can manage larger environments.
4. Alert Reduction--> Automated triage reduces analyst fatigue.
5. Cost Reduction--> Less manual investigation work.

Why This Is Important for Cloud Engineers

Because modern cloud engineering is no longer just:

        VMs
        networking
        Terraform

Modern engineers must understand:

        identity
        telemetry
        automation
        detection
        response workflows

SOAR vs SIEM (Important Distinction)

Students confuse these constantly.

| System | Purpose                     |
| ------ | --------------------------- |
| SIEM   | Collect + analyze logs      |
| SOAR   | Automate response workflows |

SIEM--> “Something suspicious happened.”

SOAR
“SOAR is security as workflow automation.”
“Detection without response is incomplete.”

        “Something suspicious happened, so I automatically:
        - enriched data
        - created ticket
        - alerted Slack
        - disabled access”

Mapping This to Current Class

Current lab already has:

| Component   | SOAR Role         |
| ----------- | ----------------- |
| Cognito     | identity source   |
| Lambda      | automation engine |
| DynamoDB    | state tracking    |
| EventBridge | orchestration     |
| WAF         | edge protection   |
| CloudWatch  | telemetry         |

DynamoDB provides the evidence context for unused-token SOAR reporting. It does not store the SOAR report itself. The detector reads token/session records from `token-tracking`, converts stale unused records into findings, sends those findings to Bedrock for analysis, and writes the final report artifacts to S3.

| DynamoDB Field / Detector Value | SOAR Reporting Use |
| ------------------------------- | ------------------ |
| `token_id` | Identifies the tracked token/session event without exposing the raw JWT |
| `username` | Shows which user/account the tracked token was issued for |
| `issued_at_iso` | Provides the human-readable issue time used to calculate token age |
| `age_minutes` | Calculated by `unused_token_detector.py` from `issued_at_iso`; shows how long the token has remained unused |
| `status` | Indicates whether the tracking record is active; the detector accepts lowercase `status` and legacy uppercase `Status` |
| `used` | Indicates whether the token/session was used; stale findings require `used = false` |
| `token_kind` | Identifies the type/source of tracked record, such as `cognito-id-token`, `synthetic-tracking-token`, or `legacy-or-unknown` |
| `records_examined` | Count of DynamoDB records scanned during the detector run |
| `matched` | Count of records matching the active/unused scan filter |
| `alerted` | Count of findings published as unused-token alerts |
| `trigger_source` | Shows whether the scan was scheduled, manual, or otherwise triggered |
| `reason` | Explains why the SOAR run was invoked, such as manual review or unused-token threshold scan |

SOAR flow:

```text
token-tracking records
  -> unused_token_detector.py scans active unused records
  -> stale records become findings
  -> Bedrock generates analysis from the findings
  -> S3 stores Markdown and JSON evidence artifacts
```

So you have

        multiple AWS services cooperating
        event-driven security
        identity-aware automation

Key Takeaways

You should leave understanding:

✔ SOAR automates security workflows
✔ Event-driven systems enable rapid response
✔ Security tools work together through orchestration
✔ Modern cloud environments require automation
✔ Detection is only the beginning

## SOAR Configuration

### SSM Parameter store

In this repo, SSM is being used as the runtime prompt store for SOAR, so the Lambda can fetch prompt text dynamically instead of hardcoding it.

1. Terraform creates an SSM parameter named /bedrock/soar-prompt in bedrock.tf:361.
2. The parameter value is loaded from your local prompt file soar-prompt.txt:1 via bedrock.tf:364.
3. The Lambda is told which parameter to read through env var SOAR_PROMPT_PARAM_NAME in lambda.tf:270.
4. At runtime, the detector reads that env var in unused_token_detector.py:17, then calls SSM GetParameter in unused_token_detector.py:58.
5. If SSM returns a value, that prompt is used and marked as source ssm in unused_token_detector.py:62.
6. If SSM is missing/unavailable, it falls back to built-in text and marks source fallback in unused_token_detector.py:67.

### Example relevant settings inside

- `unused_token_detector.py`
- `lambda.tf: resource "aws_lambda_function" "unused_token_detector"`

Terraform parameter definition:

```hcl
resource "aws_ssm_parameter" "soar_prompt" {
  name  = "/bedrock/soar-prompt"
  type  = "String"
  value = file("${path.module}/prompts/soar-prompt.txt")
}
```

Lambda environment settings:

```hcl
environment {
  variables = {
    SOAR_PROMPT_PARAM_NAME      = "/bedrock/soar-prompt"
    BEDROCK_MODEL_ID            = "us.anthropic.claude-sonnet-4-6"
    SOAR_MAX_OUTPUT_TOKENS      = "1800"
    SOAR_TEMPERATURE            = "0.3"
    SOAR_MAX_FINDINGS_IN_PROMPT = "25"
  }
}
```

CLI validation and update examples:

```bash
# Read current prompt text from SSM
aws ssm get-parameter \
  --name /bedrock/soar-prompt \
  --region us-west-2 \
  --query 'Parameter.Value' \
  --output text

# Update prompt text from local file without full terraform apply
aws ssm put-parameter \
  --name /bedrock/soar-prompt \
  --type String \
  --overwrite \
  --value "$(cat prompts/soar-prompt.txt)" \
  --region us-west-2

# Confirm Lambda has the expected parameter name configured
aws lambda get-function-configuration \
  --function-name unused_token_detector_function \
  --region us-west-2 \
  --query 'Environment.Variables.SOAR_PROMPT_PARAM_NAME' \
  --output text
```

Operational notes:

- After terraform destroy, /bedrock/soar-prompt is removed and runtime falls back to the in-code prompt.
- After terraform apply, SSM is recreated from prompts/soar-prompt.txt.
- If report style looks unexpected, check Prompt Source in the SOAR report metadata first (ssm vs fallback).

### Additional useful settings (and impact)

These are the most useful tuning knobs for SOAR report behavior in this project.

- SOAR_TEMPERATURE (example: 0.3)
  - Impact: Controls randomness/creativity of Bedrock output.
  - Lower values (0.1-0.3): More consistent, prompt-faithful responses.
  - Higher values (0.6+): More varied and creative wording, but more drift risk.

- SOAR_MAX_OUTPUT_TOKENS (example: 1800)
  - Impact: Caps maximum output size from the model.
  - Lower values: Shorter, tighter reports.
  - Higher values: More detailed/deep analysis, higher token usage and cost.

- SOAR_TARGET_WORDS (example: 350)
  - Impact: Adds a target report length instruction to the model prompt.
  - Set to 0 to disable.
  - Useful for consistently shorter summaries without changing the base prompt template.

- SOAR_MAX_BULLETS_PER_SECTION (example: 4)
  - Impact: Adds guidance that limits bullet count per section.
  - Set to 0 to disable.
  - Useful when you want compact section outputs.

- SOAR_RISK_FOCUS (example: high-and-critical)
  - Impact: Prioritizes High/Critical issues in model output.
  - Supported values: all, high, high-only, high_critical, high-and-critical.
  - Useful for management-style triage reports focused on top risk.

- BEDROCK_MODEL_ID (example: us.anthropic.claude-sonnet-4-6)
  - Impact: Determines model capability, style, and cost profile.
  - Larger/stronger models generally provide better reasoning depth.

- SOAR_MAX_FINDINGS_IN_PROMPT (example: 25)
  - Impact: How many token findings are included in prompt context.
  - Lower values: Faster/cheaper, less context.
  - Higher values: Richer context, potentially better analysis quality.

- UNUSED_TOKEN_THRESHOLD_MINUTES (example: 5)
  - Impact: Defines what counts as a stale token for detector findings.
  - Lower values: More sensitive (more alerts/noise).
  - Higher values: Less sensitive (fewer alerts, potential missed early signal).

- SOAR_PROMPT_PARAM_NAME (example: /bedrock/soar-prompt)
  - Impact: Selects which SSM parameter is used as the runtime prompt source.
  - Useful for environment-specific prompts (dev/stage/prod).

- Lambda timeout for unused_token_detector_function (example: 30-60 seconds)
  - Impact: Maximum runtime for scan + Bedrock generation.
  - Too low may cause timed out SOAR generation.

Optional advanced model controls (if you choose to wire them into code):

- SOAR_TOP_P
  - Impact: Nucleus sampling; limits token choice to top probability mass.
  - Often tuned alongside temperature, but usually leave default unless needed.

- SOAR_STOP_SEQUENCES
  - Impact: Forces generation to stop at specified delimiters.
  - Useful to prevent runaway sections or enforce strict report boundaries.

### SOAR Target Controls

These controls shape how detailed and focused SOAR analysis should be:

- SOAR_TARGET_WORDS > 0 adds a target report length.
- SOAR_MAX_BULLETS_PER_SECTION > 0 adds a per-section bullet cap.
- SOAR_RISK_FOCUS=high-and-critical prioritizes high/critical findings first.

Defaults (deep analysis mode):

```env
SOAR_TARGET_WORDS=0
SOAR_MAX_BULLETS_PER_SECTION=0
SOAR_RISK_FOCUS=all
```

Useful presets:

Short concise report:

```env
SOAR_TARGET_WORDS=300
SOAR_MAX_BULLETS_PER_SECTION=3
SOAR_MAX_OUTPUT_TOKENS=700
SOAR_TEMPERATURE=0.2
SOAR_RISK_FOCUS=all
```

Executive high-risk triage:

```env
SOAR_TARGET_WORDS=250
SOAR_MAX_BULLETS_PER_SECTION=3
SOAR_MAX_OUTPUT_TOKENS=600
SOAR_TEMPERATURE=0.2
SOAR_RISK_FOCUS=high-and-critical
```

Deep technical analysis:

```env
SOAR_TARGET_WORDS=0
SOAR_MAX_BULLETS_PER_SECTION=0
SOAR_MAX_OUTPUT_TOKENS=1800
SOAR_TEMPERATURE=0.3
SOAR_RISK_FOCUS=all
```

Runbook note:

- Recommended default for routine operations: Executive high-risk triage.
- Use Short concise report for rapid status updates and change windows.
- Use Deep technical analysis for incident response, post-incident review, and control-gap deep dives.

### SOAR_GENERATE_ON_EMPTY

Cost control feature: Enable or disable auto generate. Controls whether a SOAR report is created when there are no stale-token findings.

`true`:

- Always writes a SOAR report (even if findings=[])
- Good for heartbeat/compliance evidence (“detector ran, nothing found”)

`false`:
Only writes a SOAR report when:

- findings exist, or
- run is manual/forced (manual or force_soar)
- Good for reducing report noise/cost/storage

```
SOAR_GENERATE_ON_EMPTY=true -> soar_generated=true and files are uploaded
SOAR_GENERATE_ON_EMPTY=false -> soar_generated=false and no SOAR files uploaded
```

# IAM Roles and Policies - Least Privilege Design

The IAM design follows least privilege:

```text
Give each service only the permissions required for its specific job.
```

AWS IAM controls which services can perform actions on AWS resources. In this project, IAM is implemented through:

- Roles
- Identity-based policies
- Resource-based policies

Examples:

- API Lambdas should not have broad S3 write access unless needed.
- The unused-token detector should only scan the token table and write reports where required.
- Bedrock invocation should be limited to the Lambda that generates SOAR reports.
- DynamoDB permissions should target specific table ARNs, not all tables.

## IAM Role

An IAM role is an AWS identity that a service can assume temporarily. Instead of embedding long-term credentials in code, services such as Lambda use execution roles.

***Lambda***
In this configuration, Lambda functions do not store AWS access keys. They receive temporary permissions through their assigned IAM execution roles.

```
Lambda Function
  -> assumes IAM execution role
  -> receives temporary AWS credentials
  -> performs allowed AWS actions
  ```

### IAM Policies

IAM policies define what actions are allowed or denied. A policy answers:

```
Who can do what, on which resource?
```

Example strucure:

```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:PutItem",
    "dynamodb:UpdateItem",
    "dynamodb:Scan"
  ],
  "Resource": "arn:aws:dynamodb:us-west-2:ACCOUNT_ID:table/token-tracking"
}
```

## Lambda Execution Roles

Lambda functions do not store AWS access keys. They receive temporary permissions through their assigned IAM execution roles.

```
Lambda Function
  -> assumes IAM execution role
  -> receives temporary AWS credentials
  -> performs allowed AWS actions
```

### IAM Implementation in This Project

Each Lambda function should use an IAM role that grants only the permissions it needs. Bedrock, DynamoDB, S3, CloudWatch, EventBridge, and API Gateway are connected through scoped IAM roles, policies, and resource-based permissions.

Examples:

| IAM Component | Purpose | Example Permissions |
| --- | --- | --- |
| Lambda execution role | Allows Lambda functions to call AWS services at runtime | `logs:PutLogEvents`, `dynamodb:PutItem`, `s3:PutObject`, `bedrock:InvokeModel` |
| Lambda IAM policy | Defines what each Lambda execution role can do | CloudWatch logging, DynamoDB tracking/revocation, S3 report writes, Bedrock invocation |
| API Gateway Lambda permission | Allows API Gateway to invoke Lambda | `lambda:InvokeFunction` with principal `apigateway.amazonaws.com` |
| EventBridge Scheduler role | Allows scheduled jobs to invoke detector Lambda | `lambda:InvokeFunction` on `unused_token_detector_function` |
| S3/Lambda permission | Allows S3 event notifications to invoke translator Lambda when configured | `lambda:InvokeFunction` with principal `s3.amazonaws.com` |
| Bedrock permission | Allows SOAR Lambda to request model output | `bedrock:InvokeModel` |
| DynamoDB table permissions | Allows token tracking, revocation, and unused-token scans | `dynamodb:PutItem`, `dynamodb:UpdateItem`, `dynamodb:GetItem`, `dynamodb:Scan`, `dynamodb:Query` |
| CloudWatch Logs permissions | Allows Lambda/API workflows to write operational logs | `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` |

Cognito controls who can call the API.
IAM controls what AWS services can do after the request is accepted.

For example, Cognito/API Gateway authorizes the caller, while the Lambda execution role authorizes the Lambda function to write to DynamoDB, invoke Bedrock, write S3 reports, and publish logs.

### CloudWatch Logging

Lambda functions need permission to write logs:

```
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

These permissions allow Lambda runtime logs, application logs, and error traces to appear in CloudWatch.

### DynamoDB Access

Lambda DynamoDB permissions are scoped to the `token-tracking` and `token-revocation` tables.
Typical actions include:

```
dynamodb:PutItem
dynamodb:GetItem
dynamodb:UpdateItem
dynamodb:Scan
dynamodb:Query
```

This supports token/session tracking, revocation checks, and unused-token detection.

### S3 Access

S3 permissions are used for SOAR report storage and audit artifacts.
Typical actions include:

```
s3:PutObject
s3:GetObject
s3:ListBucket
```

The SOAR workflow writes Markdown and JSON evidence reports to the configured reports bucket.

### Bedrock Access and Lambda

The SOAR Lambda requires IAM permission to call Amazon Bedrock:

```
bedrock:InvokeModel
```

This allows the Lambda to send security-event context to the configured Bedrock model and receive the generated SOAR analysis.

### API Gateway to Lambda: Resource-Based Permissions

API Gateway does not use the Lambda execution role to invoke Lambda. Instead, Lambda has a resource-based permission allowing API Gateway to invoke it.

Example concept:

```
Principal: apigateway.amazonaws.com
Action: lambda:InvokeFunction
Resource: target Lambda function
```

This is usually implemented with aws_lambda_permission.

### EventBridge Scheduler Role
Event Bridge schedule - detection.py


EventBridge Scheduler needs permission to invoke the unused-token detector Lambda on schedule.

```
EventBridge Scheduler
  -> assumes scheduler role
  -> invokes unused_token_detector_function
```

The role should allow:

```
lambda:InvokeFunction
```

only on the dector lambda

## Summary

IAM provides the security foundation for service-to-service access in this project:

```text
Cognito/API Gateway = user authentication and API authorization, including Layer 1 scope enforcement
Lambda code = Layer 2 application RBAC using Cognito group claims
IAM roles/policies = AWS service permissions
Lambda execution roles = runtime permissions for Lambda functions
Resource policies = allow API Gateway/EventBridge/S3 to invoke Lambda
```

1. Cognito controls who can authenticate.
2. API Gateway controls which scoped access tokens can call protected API methods.
3. Lambda code decides final application-level RBAC.
4. IAM controls what AWS services are allowed to do after the request is accepted.

## The Shield - RBAC, IAM, API Gateway, WAF, and SOAR

This project uses layered security controls to protect both the public API boundary and the internal AWS service boundary.

- WAF filters malicious HTTP traffic before it reaches the API.
- API Gateway and Cognito enforce Layer 1 authorization by requiring scoped Cognito access tokens.
- Lambda enforces Layer 2 RBAC with Cognito group claims.
- IAM roles and policies control what AWS services can do after a request is accepted.
- DynamoDB, CloudWatch, EventBridge, Bedrock, and S3 support detection, reporting, and SOAR response workflows.

RBAC protects API access decisions. IAM protects AWS service-to-service actions. Together, they provide external and internal protection.

Layer 1 RBAC: API Gateway performs coarse authorization by requiring Cognito access-token scopes such as rbac-api/admin.

Layer 2 RBAC: Lambda performs final application authorization by reading Cognito group claims such as admin or user.

IAM: IAM roles and policies do not authorize end users directly. IAM authorizes AWS services, such as Lambda, EventBridge, API Gateway, S3, DynamoDB, and Bedrock, to interact with each other.

```
Layer 1 RBAC = API Gateway/Cognito scope enforcement
Layer 2 RBAC = Lambda code group-claim enforcement
IAM = service authorization, not user RBAC
```

### Layer 1 RBAC - OAuth scope-based API authorization

This is the first authorization gate before Lambda runs.
Implemented by:

```
Cognito access token
API Gateway Cognito authorizer
API Gateway authorization_scopes
```

Example:

```
authorization        = "COGNITO_USER_POOLS"
authorizer_id        = aws_api_gateway_authorizer.python_cognito.id
authorization_scopes = ["rbac-api/admin"]
```

### Layer 2 RBAC - Lambda authorization

This is the second authorization gate inside your Lambda code.

Implemented by:

```
Lambda handler
Cognito group claims
cognito:groups
```

Example:

```python
groups = claims.get("cognito:groups", "")

if "admin" not in groups:
    return {
        "statusCode": 403,
        "body": json.dumps({"message": "Access denied: admin group required"})
    }
```

Security check - What it answers:

```
Even if the request reached Lambda, is this user allowed to perform this application action?
```

Example result:

```
Valid token reaches Lambda
User is not in admin group
Lambda returns 403
```

### IAM - what can a Service do

IAM is service-to-service authorization.
Examples:

```
Can Lambda write to DynamoDB?
Can Lambda invoke Bedrock?
Can EventBridge invoke Lambda?
Can API Gateway invoke Lambda?
```


### DynamoDB Global Tables
 DynamoDB
 
 Each token gets tracked
```
{
  "token_id": "abc123",
  "username": "student1",
  "issued_at": "2026-05-19T20:00:00Z",
  "used": false
}
```

After successful authentication
easier_get_token.py
detection.py
EventBrige Rule every 10 minutes


Flow
 easier_get_token.py - after a successful authnetication it sohuld write to DynamoDB > update_token.py should mark a token as used, > unused_token_detector.py should find tokens and see if they are used = false and older than 10 minutes. Added detection.py which should detect if a token is used or not and is scheduled to run via EventBridge.
     EventBridge
    Rules
    Create Rule

    Name: unused-token-check
    Rule Type: Schedule
    Schedule: rate(10 minutes)
    Target: unused-token-detector Lambda



DynamoDB Global Tables are a multi-Region replication feature. They allow applications to read and write in multiple Regions while DynamoDB asynchronously replicates items between replica tables.

Use Global Tables when an application needs multi-Region resiliency or lower-latency local reads/writes. They are not required for this single-Region.

Important characteristics:

- Replication is asynchronous, so replicated reads are eventually consistent.
- Strongly consistent reads are only available against the local Region replica.
- Simultaneous writes to the same item in different Regions use last-writer-wins conflict resolution.
- Cross-Region replication adds cost for replicated writes, storage, and data transfer.

References:

- [DynamoDB Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
- [DynamoDB GSIs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
- [DynamoDB Naming](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html)

Legacy notes:

[textDynamoDB - GSI](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/gsi-throttling.html)
[Using GSI](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)

- Global data access with local reads and writes
    Global tables enable you to read data from and write data to any Region. DynamoDB replicates your data asynchronously to other Regions, typically within 1 second. Data replication doesn’t impact the performance of your application writes. With a global table, each replica table stores the same set of data items, and your data is eventually consistent in all Regions. While your application can perform strongly consistent reads in the same Region, the reads of data replicated from other regions of your global table are always eventually consistent, due to asynchronous nature of data replication. Transactional operations provide ACID guarantees only in the Region where the write occurs originally.

- Resiliency – Global tables provide a 99.999% uptime SLA and allow you to build disaster-proof solutions with multi-Region resiliency.
    Your application can implement custom logic to detect when a global table’s Region becomes isolated or degraded in order to redirect reads and writes to a different Region. In addition, DynamoDB tracks any writes that have been performed but haven’t yet been propagated to other Regions. If, for some reason, the communication gets interrupted, DynamoDB propagates any pending writes when the Region comes back online.

- Conflict resolution – Write conflicts can occur when writes to the same item in a global table are made simultaneously in two different Regions. To ensure data consistency, DynamoDB global tables use a last-writer-wins conflict resolution mechanism, so all the replica tables agree on the latest update and converge toward a state in which they all have identical data.

- Operational efficiency – Global tables eliminate the difficult work of replicating data so you can focus on your application’s business logic. You can monitor DynamoDB using Amazon CloudWatch (see DynamoDB Metrics and dimensions) and track global tables replication delays using the ReplicationLatency metric. ReplicationLatency is expressed in milliseconds and is emitted for every source-Region/destination-Region pair.
From a cost perspective, you pay the usual DynamoDB prices for read capacity and storage, along with data transfer charges for cross-Region replication. Write capacity is billed in terms of replicated write capacity units. Refer to Amazon DynamoDB pricing for more details.

# EventBridge

Triggers the detector Lambda -> EventBridge invokes unused_token_detector every 5 minutes (or required timing) -> `unused_token_detector` scans DynamoDB for issued-but-unused tokens

## Event Targets

[EventBridge patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
[Pattern Syntax](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-pattern.html)

[input template - reformatter](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-transform-target-input.html)
[Policy Document](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-use-resource-based.html)

To specify which events to send to a target, you create an event pattern. An event pattern defines the data EventBridge uses to determine whether to send the event to the target. If the event pattern matches the event, EventBridge sends the event to the target. Event patterns have the same structure as the events they match. An event pattern either matches an event or it doesn't.

***Patterns***

1. `event_pattern = <<PATTERN` (The Trigger)
This defines what events the rule listens for. It acts as a JSON-based filter. If an incoming event from AWS services or custom applications matches the criteria you define in this pattern, the rule will activate.Example: Listening only for EC2 Instance State-change Notification events.

Example: Listening only for `EC2 Instance State-change Notification` events.

***Inputs***
2. `input_template = <<EOT` (The Re-formatter)
Allows customizing the data passed to the target. Instead of sending the raw, bulky AWS event to your Lambda or SNS topic, the Input Transformer uses a template to extract specific variables from the event and format them into a clean, human-readable string or custom JSON payload

Example: Extracting the instance ID and state to create a custom notification: {"message": "Instance <instance_id> is now <state>"}.

Input Path is used to define variables. Use JSON path to reference items in your event and store those values in variables. For instance, you could create an Input Path to reference values in the example event by entering the following in the first text box. You can also use brackets and indices to get items from arrays.

example: This defines four variables, <timestamp>, <instance>, <state>, and <resource>. You can reference these variables as you create your Input Template.

```json
{
  "timestamp" : "$.time",
  "instance" : "$.detail.instance-id", 
  "state" : "$.detail.state",
  "resource" : "$.resources[0]"
}
```

The Input Template is a template for the information you want to pass to your target.
You can create a template that passes either a string or JSON to the target. Using the previous event and Input Path, the following Input Template examples will transform the event to the example output before routing it to a target.

***Policy document***
3. policy_document = <<POLICY (The Permissions)
This defines who or what is allowed to invoke or modify the event rule. This acts as an IAM resource-based policy. It specifies which AWS services or accounts have the permissions to send events to your custom event bus or trigger specific targets

example: Example: Granting EventBridge the permission to send messages to an SNS topic or a CloudWatch log group.

When a rule runs in EventBridge, all of the targets associated with the rule are invoked. Rules can invoke AWS Lambda functions, publish to Amazon SNS topics, or relay the event to Kinesis streams. To make API calls against the resources you own, EventBridge needs the appropriate permissions. For Amazon CloudWatch Logs resources, EventBridge uses resource-based policies. For Lambda, Amazon SNS, and Amazon SQS resources, EventBridge can use either an IAM execution role or a resource-based policy. For Kinesis streams, EventBridge uses identity-based policies.

## AI Cost Controls

Primary Cost Reduction Strategies

1. Optimize Token Usage - Token count is the biggest driver of cost

- Reduce token usage by setting appropriate `max_tokens` parameter. Set it to closely match your expected response sizes rather than using high default values
- Trim prompts: Remove verbose language, use concise phrasing, and enforce maximum prompt sizes
- Limit output length: Use explicit output length constraints to prevent unnecessarily long responses

1. Use Tiered Model Selection
Instead of always using Claude Sonnet 4.6 (your most expensive model):

- Route simple tasks to Claude 3 Haiku (faster, cheaper)
- Use Claude 3.5 Sonnet for moderate complexity
- Reserve Claude Sonnet 4.6 only for complex tasks
This can reduce costs by up to 30% without compromising accuracy

3. Implement Prompt Caching
Cache repeated prompt prefixes between requests
Can reduce input token costs by up to 85%
Particularly effective if you have static system prompts or templates
2. Use Intelligent Prompt Routing
Amazon Bedrock offers automatic routing between models in the same family based on complexity, which can significantly reduce costs.

Example: Terraform code optimization

```JSON
# Example optimization in Terraform
resource "aws_bedrock_model_invocation" "example" {
  model_id = "anthropic.claude-3-haiku-20240307-v1:0"  # Use cheaper model for simple tasks
  
  body = jsonencode({
    anthropic_version = "bedrock-2023-05-31"
    max_tokens       = 100  # Set appropriate limit instead of default
    messages = [{
      role    = "user"
      content = "Concise prompt here"  # Keep prompts short and focused
    }]
  })
}
```

# WAF Rules

References:
[WAF Rule Groups](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html)
[WAF AWS Managed Rule](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html)
[WAF DDOS](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-anti-ddos.html)


# MODELS
[Haiku listing](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-haiku-4-5.html#model-card-anthropic-claude-haiku-4-5-regional-availability)
