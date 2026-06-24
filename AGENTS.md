# Project Context

# SOAR
Use the following RBAC and evidence-storage assumptions when working in this repo:

- API Gateway and Cognito scopes provide Layer 1 authorization.
- Lambda group claims provide Layer 2 authorization.
- IAM is service-to-service authorization.
- DynamoDB stores token metadata, not plaintext tokens.
- S3 reports are evidence artifacts; Object Lock and versioning handle immutability.
- KMS is optional unless compliance or sensitive-data requirements require customer-managed keys.


## WAF Bedrock Analyzer
You are a SOC analyst assistant.

Analyze the following AWS WAF event.

Event:
{json.dumps(waf_summary, indent=2)}

Return the answer in this format:

Severity:
Possible Attack Type:
Why This Was Flagged:
Recommended Analyst Actions:
Short Executive Summary:

Keep the answer concise and practical.


## Translator



## PII Redactor