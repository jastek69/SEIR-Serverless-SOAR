# SOAR Report - unused-token-eventbridge-scheduler-1784524115 - 2026-07-20_05-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:08:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 0
- Active-Unused Records Matched: 0
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused Token Detector — Zero Records Examined

---

## 1. Severity Assessment

**Assessed Severity: INFORMATIONAL (Not a confirmed security incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that eligible records were examined and none matched the unused-token condition.

This distinction is essential. A finding of `matched: 0` against `records_examined: 100` would be a clean bill of health. A finding of `records_examined: 0` means the detector had **nothing to evaluate**, which is a different condition entirely and warrants investigation into *why* the table was empty or unpopulated at scan time.

**Confirmed evidence from the event:**
- Detector invoked successfully by EventBridge Scheduler ✅
- DynamoDB table `token-tracking` was queried ✅
- Zero records were present or eligible for examination ✅
- No alerts were raised ✅
- No matched findings ✅

**What is NOT confirmed:**
- Whether a real user authentication and JWT issuance occurred and was tracked
- Whether the token-

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
