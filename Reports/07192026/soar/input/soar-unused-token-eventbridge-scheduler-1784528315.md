# SOAR Report - unused-token-eventbridge-scheduler-1784528315 - 2026-07-20_06-18-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:18:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not an Active Threat)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed without error. The critical finding is not a malicious event but an **operational coverage gap**: `records_examined: 0` means the DynamoDB table `token-tracking` contained zero records at scan time. No JWT tokens — legitimate or malicious — were being tracked at the moment of evaluation.

**Confirmed evidence from the event:**

| Field | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | DynamoDB table was empty or returned no scannable records |
| `matched` | 0 | No tokens met the unused-within-15-minutes threshold |
| `alerted` | 0 | No alerts were raised |
| `findings_total` | 0 | No findings produced |
| `findings_sample` | `[]` | Empty result set |

**Critical distinction:** Zero matched records is **not** evidence that the detector is working correctly against a populated dataset. It is evidence that the detector had nothing to evaluate. This is an important difference: the detector cannot confirm the absence of unused tokens

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
