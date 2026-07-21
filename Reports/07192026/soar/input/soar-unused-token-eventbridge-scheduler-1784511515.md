# SOAR Report - unused-token-eventbridge-scheduler-1784511515 - 2026-07-20_01-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:38:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed without error. However, `records_examined: 0` means the detector found **no token-tracking records in the DynamoDB table `token-tracking`** to evaluate. This is a **confirmed operational gap in token visibility**, not a confirmed attack or compromise.

**Key distinctions:**

| Evidence State | Classification |
|---|---|
| Successful authentication + JWT issued | Confirmed (from event description) |
| Token unused within 15 minutes | Asserted trigger condition |
| Token registered in `token-tracking` DynamoDB table | **Not confirmed — zero records examined** |
| Malicious activity (token theft, credential stuffing, etc.) | **Hypothetical — no supporting evidence** |

The severity is held at **Informational/Low** because:

- The detector itself is functioning (it ran, examined the table, and returned results correctly).
- The zero-record result is consistent with a **registration gap**: the token was never written to `token-tracking`, so the detector had nothing to evaluate.
- No anomalous

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
