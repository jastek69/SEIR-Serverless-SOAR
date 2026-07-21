# SOAR Report - unused-token-eventbridge-scheduler-1784520515 - 2026-07-20_04-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:08:35Z
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

**Severity: INFORMATIONAL (with a process-integrity flag warranting follow-up)**

### Justification

The event contains **zero confirmed threat indicators**. No authentication anomalies, no token misuse, no lateral movement, and no privilege escalation are evidenced. The detector fired on schedule, completed its run, and returned no findings — which is a valid operational outcome.

However, the field `records_examined: 0` is the critical data point that elevates this above a clean all-clear. A properly functioning detector scanning an active authentication environment should, under most realistic conditions, examine *at least* some records — even if it matches and alerts on none of them. The combination of:

- A successful authentication event (JWT issued),
- A 15-minute non-use window (the exact trigger condition for this detector), and
- Zero records examined

creates a **process-integrity gap**: the detector *should* have had something to examine, yet it did not. This does not confirm an attack. It does confirm that the detection pipeline may not be operating as designed, which is itself a risk.

**Severity is held at INFORMATIONAL** because:
- No malicious activity is confirmed or strongly implied by the evidence.
- The zero-record result is

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
