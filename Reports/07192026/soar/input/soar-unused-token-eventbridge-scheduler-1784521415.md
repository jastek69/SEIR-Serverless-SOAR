# SOAR Report - unused-token-eventbridge-scheduler-1784521415 - 2026-07-20_04-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:23:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not a Confirmed Security Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed without error. However, `records_examined: 0` means the detector found **no token tracking records in DynamoDB at all** — it did not find unused tokens and suppress them, it found nothing to evaluate. This is a **coverage gap in the detection pipeline**, not confirmed malicious activity.

The scenario described in the prompt — "user authenticated successfully, JWT token issued, token never used within 15 minutes" — represents the **intended detection target**. However, based on the confirmed evidence in the event context, that scenario **cannot be confirmed or denied** because the token was never registered in the `token-tracking` DynamoDB table in the first place.

**Key distinctions:**

| Dimension | Status |
|---|---|
| Confirmed malicious activity | ❌ None |
| Confirmed authentication event | ⚠️ Implied by prompt context, not present in detector output |
| Confirmed token registered in DynamoDB | ❌ No — `records_examined: 0` |
| Detector operational failure |

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
