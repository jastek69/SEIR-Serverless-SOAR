# SOAR Report - unused-token-eventbridge-scheduler-1784515415 - 2026-07-20_02-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:43:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 1
- Active-Unused Records Matched: 1
- Alerts Published: 1
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- 4a8ce839-d365-4574-ab01-52ddcdf1c903 | user=admin.test | kind=cognito-id-token | age_minutes=16 | issued_at=2026-07-20T02:27:24Z

## SOAR Analysis
# Security Event Analysis: Unused JWT Token — `admin.test`

---

## 1. Severity Assessment

**Severity: LOW (Informational / Monitoring)**

**Justification:**

The event represents a **confirmed behavioral anomaly** — a Cognito ID token was issued to the account `admin.test` and was not used within the 15-minute detection threshold. This is a factual, evidence-backed finding. The token exists in the `token-tracking` DynamoDB table, was registered via the `mfa_bootstrap.py --track-token` flow, and was surfaced by the `unused_token_detector` Lambda function via EventBridge Scheduler.

**What is confirmed by evidence:**
- Token `4a8ce839-d365-4574-ab01-52ddcdf1c903` was issued at `2026-07-20T02:27:24Z`.
- The token is a `cognito-id-token` type.
- The token was 16 minutes old at detection time, exceeding the 15-minute threshold.
- The token was registered explicitly through the bootstrap/test flow (`mfa_bootstrap.py --track-token`).
- No usage event was recorded against this token in the tracking store.

**What is NOT confirmed by evidence:**
- There is no confirmed

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
