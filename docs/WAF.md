🛡️ Attach a Web Application Firewall (WAF) to the API so that:
    *Malicious or suspicious requests are blocked before Lambda
    * Students see real security controls in action
    * Logs + behavior reinforce “edge-first security”

Updated Request Flow: Client → WAF → API Gateway → Lambda → Logs
    * Critical insight: If WAF blocks → API Gateway and Lambda are NEVER reached

## What to Build

[Resource: aws_wafv2_web_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl)
    * WAF Web ACL
        Rules:
        - Block obvious bad patterns
        - Rate limiting (optional but powerful)

    * Attach WAF to API Gateway

## Task 1 — Create Web ACL

Configuration
    - Name: galactus-api-waf
    - Resource Type:: Regional resources
    - Region: Same region as API Gateway
    ***NOTE: For CloudWatch must be us-east-1

Associated Resource:
Select: API Gateway
Choose your API

## Task 2 — Rules

    ***Rule 1 — AWS Managed Rule Group***
        * Add rule → Add managed rule groups - Select: `AWSManagedRulesCommonRuleSet`

    This blocks common attacks like:
        * SQL injection patterns
        * bad headers
        * known malicious inputs

    ***Rule 2 — Rate Limiting (VERY IMPORTANT)***
        * Add rule → Rate-based rule

        Configuration:
            Limit: 100 requests per 5 minutes
            Action: Block

## Task 3 - Default Action

    Default: Allow
    Note: Only bad traffic is blocked, everything else flows through

***Terraform example usage:***
```python
resource "aws_wafv2_web_acl" "example" {
  name        = "managed-rule-example"
  description = "Example of a managed rule."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_QUERYSTRING"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }

  token_domains = ["mywebsite.com", "myotherwebsite.com"]

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

```


## Task 5 — Validate Behavior - Test

✅ Normal Request: curl "https://<api-id>/python?name=Chewbacca"

💥 Task 6 — Trigger WAF Block
Method 1 — Suspicious Input: curl "https://<api-id>/python?name=<script>alert(1)</script>"

👉 Expected: 403 Forbidden (or blocked)

Method 2 — Rate Limit (if you want drama)

Run loop: for i in {1..150}; do curl -s "https://<api-id>/python"; done

👉 Expected: Eventually blocked

🔍 Task 7 — Verify WAF Logs / Metrics
Go to: WAF → Your Web ACL → Overview

Look at:
        Allowed requests
        Blocked requests

Test:

1. Where does WAF sit?
2. What happens if WAF blocks?
3. Why is this important?
4. What kind of attacks does WAF stop?

“WAF is your bouncer. Lambda is your bartender.”

“If bad traffic reaches Lambda, you already paid for the mistake.”

“Good systems reject early and cheaply.”

🏁 Exit Criteria

Metrics to meet:

✔ WAF created
✔ Attached to API Gateway
✔ Managed rules active
✔ Rate limit configured
✔ Can trigger a block
✔ Can explain flow


## A Lambda, a WAF, a DynamoDB walk into a bar
1. Waf Logs are sent to CloudWatch
2. Lambda reads last few minutes of CloudWatch WAF logs
3. Lambda extracts the following:
```
 source IP
 country
 URI
 HTTP method
 WAF action
 terminating rule
 ```
 4. Lambda send thosee details to Bedrock
 5. Bedrock returns a SOC-style summary
  .5a Summary sent to S3 for translation
 6. Lambda prints the summary to CloudWatch
  6a. Lambda sends the summary to S3 for translation
7. Lambda sends WAF events to DynamoDB for tracking


Lambda enhancement:

Lambda Execution Role
```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:FilterLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "bedrock:InvokeModel"
          ],
          "Resource": "*"
        },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:PutItem"
         ],
         "Resource": "arn:aws:dynamodb:<region>:<account-id>:table/waf-events"
        }
      ]
    }
```



Add DynamoDB client:
```
dynamodb = boto3.resource("dynamodb")          
table = dynamodb.Table("waf-events")
```

Store Event - inside processing loop:
```
import uuid

  table.put_item(
     Item={
       "event_id": str(uuid.uuid4()),
       "timestamp": str(waf_summary["timestamp"]),
        "source_ip": waf_summary["client_ip"],
        "country": waf_summary["country"],
        "uri": waf_summary["uri"],
        "method": waf_summary["method"],
        "action": waf_summary["action"],
        "rule": waf_summary["terminating_rule_id"]
         }
)

```

DynamoDB Table Design - a new Table
- Table: waf-events
- Partition Key: event_id Type: String

DynamoDB Waf Event Table output:
```JSON
    {
      "event_id": "123456",
      "timestamp": "2026-06-23T18:00:00Z",
      "source_ip": "1.2.3.4",
      "country": "RU",
      "uri": "/python",
      "method": "GET",
      "action": "BLOCK",
      "rule": "AWSManagedRulesCommonRuleSet"
    }
```

## Testing

Resources:

ENV Variables
```
WAF_LOG_GROUP=/aws/waf/chewbacca-waf BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0 LOOKBACK_MINUTES=10
```

WAF Lambda: `waf_bedrock_analyzer.py`

Test Flow:

1. Generate a WAF event: Use the API endpoint and send something suspicious:
```
 curl "https://<api-id>.execute-api.<region>.amazonaws.com/prod/python?name=<script>alert(1)</script>"
```
Expected result: 403 Forbidden

2. Invoke the analyzer Lambda
3. Check analyzer logs ---> Go to: CloudWatch Logs → /aws/lambda/waf-bedrock-analyzer

Expected output:

    Structured WAF Event:
    {
      "action": "BLOCK",
      "client_ip": "...",
      "uri": "/prod/python",
      "terminating_rule_id": "..."
    }
    
    ===== BEDROCK SOC SUMMARY =====
    Severity:
    Possible Attack Type:
    Why This Was Flagged:
    Recommended Analyst Actions:
    Short Executive Summary:

WAF Telemetry Database

Objective:
Store WAF security events in DynamoDB so they can later be:

    searched
    correlated
    enriched
    analyzed by Bedrock
    used for SOAR workflows

Concept:
CloudWatch Logs are excellent for:

    troubleshooting
    operational visibility

But terrible for:

    correlation
    analytics
    threat history


From Part A we have: Current State---> WAF Event → CloudWatch

New State:

    WAF Event
    → CloudWatch Log
    → Lambda Parser
    → DynamoDB

## DynaoDB Purpose:
Imagine: IP 1.2.3.4 hits your API: Monday: XSS attempt Tuesday: SQL Injection Wednesday: Credential stuffing Thursday: Lizzo Injection

CloudWatch sees: individual events.
DynamoDB lets us build: Attack History

