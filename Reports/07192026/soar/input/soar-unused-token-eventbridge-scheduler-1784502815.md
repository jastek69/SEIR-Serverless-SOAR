# SOAR Report - unused-token-eventbridge-scheduler-1784502815 - 2026-07-19_23-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:13:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The core finding is `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0`. This means the detector found **no records in the DynamoDB `token-tracking` table to evaluate** — it did not find unused tokens and suppress them, nor did it find and alert on them. It found nothing to process at all.

**Confirmed evidence from the event:**
- The detector invocation itself succeeded (EventBridge triggered Lambda, Lambda ran to completion and reported structured output).
- The DynamoDB `token-tracking` table returned zero records to the detector at scan/query time.
- No Cognito JWT tokens are confirmed to be tracked in the table at this moment.
- No alerts were suppressed, no findings were hidden, and no anomalous behavior is confirmed.

**Critical architectural constraint (confirmed implementation fact):** Token tracking is **opt-in**. Only tokens explicitly registered via `mfa_bootstrap.py --track-token` are written to the `token-tracking` table. Cogn

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
