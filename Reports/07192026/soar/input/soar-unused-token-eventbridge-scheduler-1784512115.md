# SOAR Report - unused-token-eventbridge-scheduler-1784512115 - 2026-07-20_01-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:48:35Z
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

**Severity: INFORMATIONAL (with operational flag for investigation)**

**Justification:**

The detector fired as scheduled and completed without error. The core metrics are unambiguous:

| Metric | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No token-tracking records existed in DynamoDB at scan time |
| `matched` | 0 | No records met the unused-token filter criteria |
| `alerted` | 0 | No alerts were raised |
| `findings_total` | 0 | No security findings produced |

**Confirmed evidence** from the event context shows the detector executed successfully via EventBridge Scheduler and processed the DynamoDB `token-tracking` table. Zero records examined is a factual scan result, not a detection failure signal on its own.

**Critical distinction:** The severity cannot be elevated to Medium, High, or Critical based on the hypothetical scenario described in the prompt preamble ("User authenticated successfully, JWT token issued, token never used within 15 minutes") because **no such record appears in the DynamoDB table**. There is no confirmed evidence that a token meeting that description was ever registered in the tracking store. Elevating severity based on an

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
