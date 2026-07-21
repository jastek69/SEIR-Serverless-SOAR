# SOAR Report - unused-token-eventbridge-scheduler-1784514515 - 2026-07-20_02-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:28:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 1
- Active-Unused Records Matched: 1
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Detected

---

## 1. Severity Assessment

**Assessed Severity: LOW (Informational / Monitoring)**

**Justification based on confirmed evidence only:**

| Evidence Item | Confirmed? | Notes |
|---|---|---|
| Successful authentication | ✅ Yes | User authenticated and JWT issued |
| JWT token issued | ✅ Yes | Token exists in DynamoDB `token-tracking` table |
| Token unused within 15-minute threshold | ✅ Yes | Detector triggered, 1 record examined, 1 matched |
| Alert fired | ❌ No | `alerted: 0` — no alert was emitted despite the match |
| Findings generated | ❌ No | `findings_total: 0`, `findings_sample: []` |
| Malicious activity confirmed | ❌ No | No corroborating evidence in supplied context |

**Critical observation:** The detector matched 1 record (`matched: 1`) but produced zero findings and zero alerts (`alerted: 0`, `findings_total: 0`). This is a **confirmed implementation defect** — a matched record that does not produce a finding or alert represents a silent failure in the detection pipeline. The severity of the *security event itself* (

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
