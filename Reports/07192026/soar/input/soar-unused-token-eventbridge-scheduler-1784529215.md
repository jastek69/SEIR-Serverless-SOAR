# SOAR Report - unused-token-eventbridge-scheduler-1784529215 - 2026-07-20_06-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:33:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (No Active Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric here is `records_examined: 0`, not `matched: 0`. Zero records examined means the DynamoDB table `token-tracking` contained no records eligible for evaluation at the time of invocation — not that eligible records existed and were cleared, and not that a threat was detected and suppressed.

| Evidence Item | Status | Confidence |
|---|---|---|
| Detector invoked successfully | Confirmed | High |
| DynamoDB table `token-tracking` queried | Confirmed | High |
| Zero records present or eligible at scan time | Confirmed | High |
| Unused token threat detected | **Not confirmed** | N/A |
| Authentication abuse or token theft | **Hypothetical only** | N/A |

**Risk trade-off note:** The zero-records result is operationally ambiguous. It is simultaneously the expected result when no tokens have been registered (correct behavior) and a potential blind spot if tokens *should* have been registered but were not. The severity remains informational because there is no positive finding — no

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
