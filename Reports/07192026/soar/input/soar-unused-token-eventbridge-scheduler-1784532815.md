# SOAR Report - unused-token-eventbridge-scheduler-1784532815 - 2026-07-20_07-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:33:35Z
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

**Severity: INFORMATIONAL / LOW (Operational Gap — Not a Confirmed Security Incident)**

**Justification:**

The detector fired as scheduled and completed without error. The critical finding is not a malicious event — it is that `records_examined: 0`, meaning the DynamoDB table `token-tracking` contained **zero records at scan time**. No tokens were evaluated, no anomalies were confirmed, and no alerts were raised.

This must be interpreted carefully:

| Dimension | Finding | Confidence |
|---|---|---|
| Authentication event occurred | Assumed from event description | Hypothetical (not in JSON payload) |
| JWT token issued | Assumed from event description | Hypothetical (not in JSON payload) |
| Token registered in `token-tracking` | **Not confirmed** — 0 records examined | Confirmed gap |
| Token evaluated for non-use | **Did not occur** — 0 records examined | Confirmed gap |
| Malicious activity detected | None | N/A |
| Detector failure | Not evidenced — detector ran and returned cleanly | Confirmed operational |

**The severity is not elevated based on hypothetical attack paths.** The confirmed finding is a **coverage gap**:

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
