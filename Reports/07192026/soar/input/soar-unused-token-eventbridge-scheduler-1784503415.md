# SOAR Report - unused-token-eventbridge-scheduler-1784503415 - 2026-07-19_23-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:23:35Z
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

**Severity: INFORMATIONAL (with operational monitoring gap warranting LOW-severity follow-up)**

### Justification

The detector fired as scheduled and completed without error. The confirmed evidence is:

| Evidence Item | Status |
|---|---|
| Successful authentication | Confirmed (stated in event) |
| JWT token issued | Confirmed (stated in event) |
| Token unused within 15-minute threshold | Stated trigger condition |
| Records examined by detector | **Zero** |
| Matched unused tokens | Zero |
| Alerts raised | Zero |

The critical finding here is **not** a malicious actor — it is an **operational gap**: the detector examined zero records despite a token having been issued. This means the detector had no data to evaluate. A zero-record examination result when a token is known to have been issued indicates a **tracking registration gap**, not a confirmed attack.

**Why severity is not elevated:** There is no evidence of credential misuse, lateral movement, privilege escalation, or token replay. Elevating severity based on the hypothetical threat of an attacker obtaining an untracked token would be speculative given the available evidence. The risk is real but the threat is unconfirmed.

**Why a LOW operational flag is warran

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
