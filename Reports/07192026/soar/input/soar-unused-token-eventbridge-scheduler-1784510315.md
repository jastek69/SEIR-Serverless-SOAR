# SOAR Report - unused-token-eventbridge-scheduler-1784510315 - 2026-07-20_01-18-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:18:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 2
- Active-Unused Records Matched: 2
- Alerts Published: 1
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- d35ace28-2be4-4e70-8530-37dcae454863 | user=admin.test | kind=cognito-id-token | age_minutes=16 | issued_at=2026-07-20T01:02:07Z

## SOAR Analysis
# Security Event Analysis: Unused JWT Token — `admin.test`

---

## 1. Severity Assessment

**Severity: LOW (Informational / Monitoring)**

**Justification:**

The event represents a **confirmed, evidence-based anomaly**: a Cognito ID token was issued to the account `admin.test`, registered in the `token-tracking` DynamoDB table via the `mfa_bootstrap.py --track-token` flow, and was not used within the 15-minute detection threshold. The detector functioned correctly — 2 records were examined, 2 matched the unused-token filter, and 1 alert was raised for the finding in scope.

**What is confirmed by evidence:**
- A valid Cognito ID token (`token_id: d35ace28-2be4-4e70-8530-37dcae454863`) was issued at `2026-07-20T01:02:07Z`.
- The token is of kind `cognito-id-token`, explicitly registered via the bootstrap/test flow.
- The token was 16 minutes old at detection time, exceeding the 15-minute threshold.
- No usage event was recorded against this token in the `token-tracking` table.

**What is not confirmed:**
- There is no evidence of credential theft, session hijacking

> Model output reached its configured limit. The following deterministic recovery sections complete the report.

## 4. Short Executive Summary

No stale active-unused tracking records matched this detector run. This result is not evidence that a Cognito JWT was issued and left unused, unless the record was explicitly registered from the Cognito bootstrap flow. Cognito clients outside that flow are not automatically linked to tracking.

## 5. Recommended Remediation Explanations

- Keep the DynamoDB attribute name consistently lowercase as `status`.
- Track actual Cognito session identifiers through an explicit registration and usage-update flow.
- Report DynamoDB `ScannedCount` separately from matching record count.
- Generate incident reports only from evidence supplied to the model.

## 6. Possible Code Snippets and Walkthroughs for Remediation

```python
response = tracking.scan(**scan_kwargs)
records_examined += response.get("ScannedCount", 0)
matching_records += response.get("Count", 0)
```

Register a stable Cognito session identifier at issuance, then update that same record when an authorized API request succeeds.
