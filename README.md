☁️ Class 7 Armageddon - Brotherhood of Evil jerMutants - Wolfpack

![Blackneto.jpg](/images/Blackneto.jpg "sebekgo logo")

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A51.9-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-Edge_Security-yellow?style=for-the-badge&logo=amazon-aws)
![WAFv2](https://img.shields.io/badge/AWS_WAFv2-Real_Time_Logging-red?style=for-the-badge&logo=amazonaws)
![Bedrock](https://img.shields.io/badge/Amazon_Bedrock-Auto_IR-black?style=for-the-badge&logo=amazon-aws)
![Multi_Region](https://img.shields.io/badge/Multi_Region-Transit_Gateway-blue?style=for-the-badge)
![Compliance](https://img.shields.io/badge/Compliance-HIPAA_Inspired-purple?style=for-the-badge)
![Observability](https://img.shields.io/badge/Observability-CloudWatch_&_Bedrock-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production_Grade-success?style=for-the-badge)

This repository contains Serverless solutions with Lambda, S3, IAM permissions, API Gateway and WAF for security

---

## ✍️ Authors & Acknowledgments

**Credit: TheoRec** for the orginal starting code base




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

## Core services:
    * API Gateway (REST or HTTP API)
    * Lambda (order creation, payment processor, notification worker)
    * Aurora Serverless v2 (orders + line items)
    * EventBridge (OrderCreated, OrderPaid events)
    * SQS (work queue for payment processing + DLQ)
    * SNS (customer notification topic)
    * S3 (optional: for order receipts/invoices)

## Results:
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

### Lambda

- Smoke test (creates log group if it doesn't exist; expect a JS error on empty payload, not an import error):
    `aws lambda invoke --function-name image_processor --region us-west-2 --payload '{}' response.json && cat response.json`

- Invoke function using payload file:
    `aws lambda invoke --function-name image_processor --region us-west-2 --payload fileb://event.json response.json`

- Get function configuration:
    `aws lambda get-function-configuration --function-name image_processor`

- Get Lambda resource policy:
    `aws lambda get-policy --function-name image_processor`

### S3 image resizing test flow

1. Upload a test image to source bucket:
    `aws s3 cp ./images/test_images/sample.jpg s3://sourcebucket-nxh00b/sample.jpg`

2. Verify output appears in destination bucket:
     `aws s3 ls s3://destinationbucket-nxh00b --recursive`

3. Download processed image:
    `aws s3 cp s3://destinationbucket-nxh00b/sample.jpg ./images/test_images/resized-sample.jpg`

4. Verify S3 notification config:
     `aws s3api get-bucket-notification-configuration --bucket sourcebucket-nxh00b`

### Terraform + deployed IDs

- Show outputs:
    `terraform output -no-color`

- Show one output value:
    `terraform output -raw lambda_function_arn`

### Debug helpers

- Confirm AWS identity:
    `aws sts get-caller-identity`

- Confirm configured region:
    `aws configure get region`

- Enable detailed CLI debug output:
    `aws <service> <command> --debug`

### PowerShell alternative

If Git Bash still rewrites paths, run AWS commands in PowerShell:
`aws logs tail "/aws/lambda/image_processor" --since 10m --follow`



## Quick Start Test (Current Deployment)

Use these exact values from your current Terraform state/output:

- Lambda function: `image_processor`
- Source bucket: `sourcebucket-nxh00b`
- Destination bucket: `destinationbucket-nxh00b`

### 0) Smoke test the Lambda (creates the log group)

`aws lambda invoke --function-name image_processor --region us-west-2 --payload '{}' response.json && cat response.json`

> Expected: `FunctionError: Unhandled` with a JS-level error (missing `event.Records`). This is normal for an empty payload — it confirms the runtime is working. An `ImportModuleError` means the zip or runtime is misconfigured.

### 1) Start Lambda logs (Git Bash-safe)

`MSYS_NO_PATHCONV=1 aws logs tail '/aws/lambda/image_processor' --region us-west-2 --since 10m --follow`

Optional: confirm the log group exists (Git Bash-safe):

`MSYS_NO_PATHCONV=1 aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/' --region us-west-2 --query "logGroups[?contains(logGroupName, 'image_processor')].logGroupName" --output text`

### 2) Upload a test image to source bucket

`aws s3 cp ./images/test_images/sample.jpg s3://sourcebucket-nxh00b/sample.jpg`

### 3) Check destination bucket for output

`aws s3 ls s3://destinationbucket-nxh00b --recursive`

### 4) Download the resized image

`aws s3 cp s3://destinationbucket-nxh00b/sample.jpg ./images/test_images/resized-sample.jpg`

### 5) Verify S3 trigger wiring

`aws s3api get-bucket-notification-configuration --bucket sourcebucket-nxh00b`

### 6) Verify Lambda invoke permission for S3

`aws lambda get-policy --function-name image_processor`
    





## CloudWatch
Lambda log group and what to click once you’re in CloudWatch so you can follow new invocations live.
Use this direct Console path (already scoped to your region/log group):

https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/%2Faws%2Flambda%2Fimage_processor

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



# Reference Links:
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

# Construct the URL manually:
To construct the URL manually or for specific resources, you can concatenate the API ID and Region:
    - Base URL: `Format: https://{restapi_id}.execute-api.{region}.amazonaws.com/{stage_name}`
    - Full Resource Path: To point to a specific endpoint, append the resource path: `${aws_api_gateway_stage.example.invoke_url}/items`

To Run:
curl "https://f3sdn1pb3a.execute-api.us-west-2.amazonaws.com/prod/PythonResource"

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

2. List top-level prefixes in the bucket:

```bash
aws s3 ls s3://<waf-logs-bucket>/
```

3. Check for recently written objects:

```bash
aws s3api list-objects-v2 \
    --bucket <waf-logs-bucket> \
    --max-items 20 \
    --query "Contents[].{Key:Key,LastModified:LastModified,Size:Size}" \
    --output table
```

4. Filter only the AWS log prefix:

```bash
aws s3api list-objects-v2 \
    --bucket <waf-logs-bucket> \
    --prefix AWSLogs/ \
    --max-items 20 \
    --query "Contents[].Key" \
    --output table
```

5. Confirm logging is attached to your Web ACL:

```bash
aws wafv2 list-web-acls --scope REGIONAL --region us-west-2
aws wafv2 get-logging-configuration --resource-arn <web-acl-arn> --region us-west-2
```

6. Optional quick traffic test, then re-check S3:

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
https://github.com/BalericaAI/lambda/blob/main/lessond_cognito/readme.md

[Cognito REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html)

Cognito — What It Is, Purpose, and Why It Matters

What is Cognito?
In simple terms: ---> “Cognito answers one question: Who are you?”

Amazon Cognito is AWS’s managed identity service.

It handles:

    User authentication (login, passwords, tokens)
    User management (accounts, groups)
    Token generation (JWTs) for APIs


https://aws.amazon.com/pm/cognito/?trk=36e1404e-1051-48b6-9dd0-51db40b9c756&sc_channel=ps&ef_id=CjwKCAjwqubPBhBOEiwAzgZX2nhsEiOHEJQVaqlAYrksnh6lOFWjvE4VxyRyQ3izPOoltgjOxDh6mBoCOngQAvD_BwE:G:s&s_kwcid=AL!4422!3!795794010901!p!!g!!cognito!23527793912!187898877050&gad_campaignid=23527793912&gbraid=0AAAAADjHtp8JXL4yKgorV0cpJGxLu-Nuy&gclid=CjwKCAjwqubPBhBOEiwAzgZX2nhsEiOHEJQVaqlAYrksnh6lOFWjvE4VxyRyQ3izPOoltgjOxDh6mBoCOngQAvD_BwE



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
    * name of lambda
    * mail, ph, and username
    * enforce MFA
    * select attributes
    * create user directory
    * view sign-in page
    * selct user Pool and configure MFA with Authenticator apps, email, SMS for lab - in an office use auth and passkey

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
https://stackoverflow.com/questions/44244441/how-to-create-a-secret-hash-for-aws-cognito-using-boto3

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




# Cognito JWT Flow Summary:
reference links:
https://repost.aws/knowledge-center/cognito-unable-to-verify-secret-hash
https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html

1. Create/run a Python script to generate the Cognito `SECRET_HASH`
	* Obtain `SECRET_HASH` by running the Python script: python auth.py ziontheo 7im6sn4tj742m8s7njfr7olqga ri6fb0nihm6p3p05k36g32318o74olvh695ht7455o64728g8t5

2. Generate the `SECRET_HASH` by running the python script using:
	* Cognito username
	* Cognito app client ID
	* Cognito app client secret value

3. Call `initiate-auth` to start authentication. This initiates an authorization request and returns a session when MFA is required.

Inputs:
- `USERNAME`
- `PASSWORD`
- `SECRET_HASH`

Output with MFA enabled:
- `ChallengeName`
- `Session`

4. Call `respond-to-auth-challenge` to respond to the MFA session challenge.

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

5. Retrieve JWTs from `AuthenticationResult`.
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



# TODO
- clean up TF code & upload to github
- get second lambda endpoint into API gateway
- have clickable output for both endpoints, so both links end up with a http or rest based result
- be able to understand, explain, and defend all TF code arguments
 - 




 # APPENDIX

 ## WAFV2 Notes

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

Cognito app clients: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html
Cognito MFA: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html
API Gateway Cognito authorizer: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html


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
* ID token: accepted for basic REST API Cognito authorizer authentication.
* Access token: use it when the API method has Authorization scopes configured and the token carries an accepted scope.


APIs or Cognito self-service endpoints. (docs.aws.amazon.com)

Cognito tokens:
docs.aws.amazon.com
Token	Main question	Typical contents	In your API test
ID_TOKEN	“Who is this user?”	Identity claims such as username, email, name, aud, token_use = "id"	Works for basic Cognito authentication on a REST API method
ACCESS_TOKEN	“What is this user/app allowed to do?”	Scopes, groups, client_id, token_use = "access"	Works when the REST API method is configured to require accepted authorization scopes

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

4. API Gateway will evaluate:
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
Summary: Cognito for OAuth/JWT identity. DynamoDB for session metadata, token revocation records, OAuth state/nonce, device tracking, and audit events.
- Cognito: 
  - OAuth/JWT identity
  - issue ID/access/refresh tokens
  - API validates access tokens locally using Cognito’s JWKS/public keys.


RBAC — Role-Based Access Control

What is RBAC?

Role-Based Access Control (RBAC) is a security model where:

Access is assigned to roles, not directly to users.

Simple Model---> User → Role → Permissions → Resource

| User     | Role    | Access            |
| -------- | ------- | ----------------- |
| student1 | student | `/python`         |
| admin1   | admin   | `/python + /node` |


Purpose of RBAC in This Lab

So far:

WAF → filters traffic
Cognito → verifies identity

Now: RBAC → controls what authenticated users can do
Translation: “Not everyone who gets in should have full access.”

Updated System Flow: Client → WAF → API Gateway (Auth) → Lambda (RBAC decision)

Important:

Authentication happens at API Gateway
Authorization (RBAC) often happens in Lambda

RBAC in Cognito

With Amazon Cognito, RBAC is implemented using:

Groups

Examples:

    students
    admins
    Lizzo lovers
    Chewbacca
    Malgus Clan

Token Claims

When a user logs in, their JWT contains:

    "cognito:groups": ["students"]


Why RBAC Matters????

1. Scalability

Instead of: ---> assigning permissions per user ❌
You:---> assign roles once✅
Or you could assign multiple times to Lizzo.  You want that???

2. Consistency

All users in a role behave the same way

3. Security

You follow:

    Least Privilege Principle

Users only get what they need

Connecting RBAC to Microsoft / Active Directory

RBAC in Microsoft World

In:

Active Directory
Microsoft Entra ID

RBAC is implemented through:

✔ Security Groups

Examples:

        Domain Users
        Admins
        HR
        Finance

| Concept      | Cognito          | Microsoft           |
| ------------ | ---------------- | ------------------- |
| User         | User Pool User   | AD User             |
| Group        | Cognito Group    | Security Group      |
| Role         | Group membership | Group membership    |
| Token Claims | JWT              | SAML / OAuth claims |

Remember this: “Cognito groups = AD security groups. Same idea, different platform.”

Mental Model (Important)

Cognito (This Lab)
    Lightweight
    API-focused
    Cloud-native

AD / Entra SEIR 
    Enterprise identity
    Corporate networks
    SSO across apps

“Today you learn RBAC in Cognito. Later you will see the same model in AD and Entra—just bigger and more complex.”

RBAC Decision Point in System

Where does RBAC happen?

Two options:

        1. API Gateway (Advanced)
        
        Harder
        Less flexible
        
        2. Lambda (Recommended for Lab)
        
        Why Lambda?
        Easy to understand
        Easy to debug
        Real-world pattern for many systems

Example RBAC Logic

In Lambda:

        groups = event["requestContext"]["authorizer"]["claims"].get("cognito:groups", [])
        
        if "admin" in groups:
            # full access
        elif "student" in groups:
            # limited access
        else:
            # deny

“Your code decides access based on identity claims.”

NOTE:

Authentication ≠ authorization
Just because you log in doesn’t mean you can do everything
Systems enforce behavior based on identity
“RBAC is how companies survive audits.”


- DynamoDB
  - Tables for tokens - stores session/token metadata - session tracking
  - DynamoDB TTL expires records automatically
  - DynamoDB: store business event state and processing records
  - DynamoDB support revocation - denylist check
- Secrets Manager stores app secrets, OAuth client secrets, API keys, webhook signing secrets, etc. 
- AWS Secrets Manager - rotation
- OPA or Vault: store secrets
- Cognito: Stateless

Example DynamoDB table:
```
AuthSessionEvents / TokenMetadata
- user_id
- session_id
- refresh_token_id_hash
- device_id
- provider: cognito/google/github/etc
- status: active/revoked/expired
- issued_at
- expires_at
- revoked_at
- ip_address
- user_agent
- last_seen_at
- ttl
```

NOTES:
Cognito access tokens are normally valid until expiration. 
For immediate revocation, use either:
    - short access-token lifetimes
    - refresh-token revocation
    - DynamoDB-backed denylist check for sensitive operations







# DynamoDB
- DynamoDB for
  - Tables for tokens - stores session/token metadata - session tracking
  - TTL expires records automatically
  - store business event state and processing records
  - Revocation - denylist check

### Create: - lessonf walkthru
- DynamoDB
- lambda functions:
    - get_token.py 
    - update_token.py
    - unused-token-detector.py - locate unused tokens
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




***CORE FUNADEMENTAL SECURITY PRINCIPAL:***
refer to DynamoDB lambda workflow

this is the core of making the token system secure and auditable.

How It Works

When a token is issued, you write one record to tracking table and optionally one record to revocation table only when revoked.
You never store the raw token in DynamoDB, only token_hash.
You validate by hashing the incoming token and checking:
revocation table first (fast denylist check)
tracking table status and expiry
expires_at is Unix epoch seconds so DynamoDB TTL can auto-delete old records.
Write Path (Issue Token)
Use this in get_token.py.

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

Read Path (Validate Token)
This logic can live in python_lambda.py and node_lambda.js, or a shared authorizer Lambda.

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



TODO:
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
token-tracking

### Create DynamoDB
courtesy: kakakakakku

This pattern creates an Amazon API Gateway REST API that integrates with an Amazon DynamoDB table.

Learn more about this pattern at Serverless Land Patterns: http://serverlessland.com/patterns/apigw-dynamodb-terraform

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the AWS Pricing page for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

This pattern creates an Amazon API Gateway REST API that integrates with an Amazon DynamoDB table named "Pets". The API includes an API key and usage plan. The DynamoDB table includes a Global Secondary Index named "PetsType-index". The API integrates directly with the DynamoDB API and supports PutItem and Query actions.



## Testing

Once the application is deployed, you can test it using the following instructions.

1. The terraform outout included two things:
	* The url to the deployed API.
	* The Key to use with the deployed API.
1. To invoke the DynamoDB **PutItem** action to add a new item to the DynamoDB table:
	* Run the below command after you replace <KEY> and <URL> with the terraform output from earlier.
	```
	curl -H 'x-api-key: <KEY>' -H 'Content-Type: application/json' --request POST '<URL>' --data-raw '{ "PetType": "dog", "PetName": "tito", "PetPrice": 250 }'

	```
	* Repeate the process as many times as you can, try doing it with different Pet Types
1. Invoke the DynamoDB **Query** action to query items by PetType in the DynamoDB table:
	* Run the below command after you replace <KEY> and <URL> with the terraform output from earlier. Append the PetType to the URL (e.g. `/dog`).
	```
	curl -H 'x-api-key: <KEY>' --request GET '<URL>/dog'
	```
	* Repeate the process as many times as you can with different Pet Types
	* You should receive a "200 OK" response with a list of the matching results. Example: 
	```
	{
		"pets": [
			{
				"id": "45b33352-fea0-4e8b-8c7a-6be11ec4ff80",
				"PetType": "dog",
				"PetName": "tito",
                "PetPrice": "250"
			}
		]
	}
	```

## Cleanup
 
1. Change directory to the pattern directory:
    ```
    cd serverless-patterns/apigw-dynamodb-terraform
    ```
1. Delete all created resources
    ```bash
    terraform destroy
    ```
1. During the prompts:
    * Enter yes
1. Confirm all created resources has been deleted
    ```bash
    terraform show
    ```
----


## Create Event Bridge
courtesy: apopa57

[EventBridge + lambda](https://github.com/aws-samples/serverless-patterns/tree/main/lambda-eventbridge-terraform)

This pattern deploys an API Gateway HTTP API with a custom domain configuration and permissions to publish HTTP requests as events to EventBridge.

Learn more about this pattern at Serverless Land Patterns: [https://serverlessland.com/patterns/apigateway-http-eventbridge-custom](https://serverlessland.com/patterns/apigateway-http-eventbridge-custom)

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the [AWS Pricing page](https://aws.amazon.com/pricing/) for details.

## Deployment Instructions

1. Create a new directory, navigate to that directory in a terminal and clone the GitHub repository:
    ```
    git clone https://github.com/aws-samples/serverless-patterns
    ```
1. Change directory to the pattern directory:
    ```
    cd apigw-eventbridge
    ```
1. From the command line, use AWS SAM to deploy the AWS resources for the pattern as specified in the template.yml file:
    ```
    sam deploy --guided --capabilities CAPABILITY_NAMED_IAM
    ```
1. During the prompts:
    * Enter a stack name
    * Enter the desired AWS Region
    * Allow SAM CLI to create IAM roles with the required permissions.

    Once you have run `sam deploy --guided` mode once and saved arguments to a configuration file (samconfig.toml), you can use `sam deploy` in future to use these defaults.

1. Note the outputs from the SAM deployment process. These contain the resource names and/or ARNs which are used for testing.

## How it works

The endpoint that will be created might look like, for example: `http://dev-events.example.com/apigw2eb/{source}/{detailType}`

Simply specify any `source` and `detailType` as a path parameters. The `body` of the request could be any valid json object.

### The AWS SAM template deploys the following resources

| Type | Logical ID |
| --- | --- |
| AWS::ApiGatewayV2::Api | HttpApi |
| AWS::Events::EventBus | ApplicationEventBus |
| AWS::ApiGatewayV2::Stage | HttpApiStage |
| AWS::ApiGatewayV2::ApiMapping | HttpApiMapping |
| AWS::IAM::Role | HttpApiIntegrationEventBridgeRole |
| AWS::ApiGatewayV2::Integration | HttpApiIntegrationEventBridge |
| AWS::ApiGatewayV2::Route | HttpApiRoute |
| AWS::CloudFormation::Stack1 | apigw2eb-[STAGE] |

When you send an HTTP POST request, the API Gateway publishes an event to the custom event bus in EventBridge.

## Testing

Use your preferred terminal to send a http request.

```bash
curl --location --request POST 'https://dev-events.example.com/apigw2eb/mysource/mydetailtype' \
--header 'Content-Type: application/json' \
--data-raw '{
    "mybody": {
        "attr1": 1,
        "attr2": [1,2]
    }
}'
```

The response would be like:

```bash
{
    "Entries": [
        {
            "EventId": "1a15592f-87a0-e0d8-8e21-172e63c57212"
        }
    ],
    "FailedEntryCount": 0
}
```

This means your event was published successfuly.

So, the Lambda event for the request above will look like:

```json
{
    "version": "0",
    "id": "1a15592f-87a0-e0d8-8e21-172e63c57594",
    "detail-type": "mydetailtype",
    "source": "com.mycompany.mysource",
    "account": "xxxxxxxxxx74",
    "time": "2021-04-03T14:45:32Z",
    "region": "eu-central-1",
    "resources": [],
    "detail": {
        "mybody": {
            "attr1": 1,
            "attr2": [1, 2]
        }
    }
}
```

Create your own either Lambda function or any other consumer for events you send with this API Gateway endpoint.

## Cleanup

1. Delete the stack
    ```bash
    aws cloudformation delete-stack --stack-name STACK_NAME
    ```
1. Confirm the stack has been deleted
    ```bash
    aws cloudformation list-stacks --query "StackSummaries[?contains(StackName,'STACK_NAME')].StackStatus"
    ```
----

## Additional resources

- [Amazon API Gateway V2](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_ApiGatewayV2.html)
- [Amazon EventBridge](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_Events.html)

---


### Navigation
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
Update your previous Lambda with this: https://github.com/BalericaAI/lambda/blob/main/lessonf/lambda/update_token.py

If you want to play with headers then.... Pass token_id as header: -H "x-token-id: abc123"

Phase 4 — Create Detection Lambda

Lambda Name: unused-token-detector


Purpose

Find tokens:

        used = false
        AND
        older than 10 minutes


unused_token_detector.py  Here: https://github.com/BalericaAI/lambda/blob/main/lessonf/lambda/unused_token_detector.py

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


# GLOSSARY


### DynamoDB Global Tables
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

## Event Targets
[EventBridge patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
[Pattern Syntax](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-pattern.html)

[impute template - reformatter](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-transform-target-input.html)
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

# S3




# AWS API Gateway to Amazon EventBridge




credit: kakakakakku

# Amazon API Gateway HTTP API to Amazon EventBridge

This pattern creates an HTTP API endpoint that directly integrates with Amazon EventBridge

Learn more about this pattern at Serverless Land Patterns: https://serverlessland.com/patterns/apigateway-http-eventbridge-terraform

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the [AWS Pricing page](https://aws.amazon.com/pricing/) for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

## Requirements

* [Create an AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) if you do not already have one and log in. The IAM user that you use must have sufficient permissions to make necessary AWS service calls and manage AWS resources.
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
* [Git Installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started) installed

## Deployment Instructions

1. Create a new directory, navigate to that directory in a terminal and clone the GitHub repository:
    ``` 
    git clone https://github.com/aws-samples/serverless-patterns
    ```
1. Change directory to the pattern directory:
    ```
    cd serverless-patterns/apigw-http-eventbridge-terraform
    ```
1. From the command line, initialize terraform to  to downloads and installs the providers defined in the configuration:
    ```
    terraform init
    ```
1. From the command line, apply the configuration in the main.tf file:
    ```
    terraform apply
    ```
1. During the prompts:
    * Enter yes
1. Note the outputs from the deployment process. These contain the resource names and/or ARNs which are used for testing.

## How it works

This pattern creates an Amazon API gateway HTTP API endpoint. The endpoint uses service integrations to directly connect to Amazon EventBridge.

## Testing

To test the endpoint first send data using the following command. Be sure to update the endpoint with endpoint of your stack.

```
curl --location --request POST '<your api endpoint>' --header 'Content-Type: application/json' \
--data-raw '{
    "Detail":{
        "message": "Hello From API Gateway"
    }
}'
```

Then check the logs for the Lambda function from the Lambda console.

## Cleanup
 
1. Change directory to the pattern directory:
    ```
    cd serverless-patterns/apigw-http-eventbridge-terraform
    ```
1. Delete all created resources
    ```bash
    terraform destroy
    ```
1. During the prompts:
    * Enter yes
1. Confirm all created resources has been deleted
    ```bash
    terraform show
    ```
----
Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

SPDX-License-Identifier: MIT-0


```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.64.0"
    }
  }
}

provider "aws" {

}

data "aws_caller_identity" "current" {}

data "archive_file" "LambdaZipFile" {
  type        = "zip"
  source_file = "${path.module}/src/eventbridge_function.py"
  output_path = "${path.module}/eventbridge_function.zip"
}

resource "aws_lambda_function" "eventbridge_function" {
  function_name = "EventBridgeScheduleTargetPython"
  filename      = data.archive_file.LambdaZipFile.output_path
  handler       = "eventbridge_function.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "python3.14"
  memory_size   = 128
  timeout       = 30
}

resource "aws_iam_role" "scheduler_role" {
  name = "EventBridgeSchedulerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_invoke_policy" {
  name = "EventBridgeInvokeLambdaPolicy"
  role = aws_iam_role.scheduler_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowEventBridgeToInvokeLambda",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Effect" : "Allow",
        "Resource" : aws_lambda_function.eventbridge_function.arn
      }
    ]
  })
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "LambdaExecutionRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "PublishLogsPolicy"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLambdaFunctionToCreateLogs",
        "Action" : [
          "logs:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.eventbridge_function.function_name}:*"
        ]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "invoke_lambda_schedule" {
  name = "InvokeLambdaSchedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "rate(5 minute)"
  target {
    arn = aws_lambda_function.eventbridge_function.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input = jsonencode({"input": "This message was sent using EventBridge Scheduler!"})
  }
}

output "ScheduleTargetFunction" {
  value = aws_lambda_function.eventbridge_function.arn
  description = "The ARN of the Lambda function being invoked from EventBridge Scheduler"
}

output "ScheduleName" {
  value = aws_scheduler_schedule.invoke_lambda_schedule.name
  description = "Name of the EventBridge Schedule"
}

```