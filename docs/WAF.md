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

Student passes when:

✔ WAF created
✔ Attached to API Gateway
✔ Managed rules active
✔ Rate limit configured
✔ Can trigger a block
✔ Can explain flow
