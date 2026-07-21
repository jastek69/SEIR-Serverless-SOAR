# SOAR Report - unused-token-eventbridge-scheduler-1784506715 - 2026-07-20_00-18-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:18:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed without error. However, `records_examined: 0` means the detector found **no token tracking records in DynamoDB at scan time** — it did not find unused tokens and suppress them, nor did it encounter an error processing records. The detector ran cleanly against an empty (or effectively empty) result set.

**Critically, this is not confirmation that no tokens exist in the environment.** The implementation facts explicitly state that only tokens registered via `mfa_bootstrap.py --track-token` are tracked. Standard Cognito JWT issuance flows used by other clients are **not automatically registered** in the `token-tracking` DynamoDB table. This creates a **confirmed coverage gap**: the detector's zero-finding result cannot be interpreted as "no unused tokens exist in the environment." It can only be interpreted as "no explicitly registered tokens were found in the tracking table at scan time."

**No confirmed attack is evidenced.** The severity is kept at Informational/Low because:
- No anomalous authentication events are confirmed in the supplied context.
- No matched

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
