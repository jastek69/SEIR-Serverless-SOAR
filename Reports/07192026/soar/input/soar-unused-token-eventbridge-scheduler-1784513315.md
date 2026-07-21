# SOAR Report - unused-token-eventbridge-scheduler-1784513315 - 2026-07-20_02-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:08:35Z
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

**Severity: INFORMATIONAL (Not a confirmed security incident)**

**Justification:**

The detector fired as scheduled and completed its run without error. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records** at the time of evaluation — not that records existed and were filtered out. This is a **confirmed operational observation**, not a confirmed threat signal.

The distinction matters significantly:

| Metric | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No records present in the token store at scan time |
| `matched` | 0 | No records met the unused-token criteria |
| `alerted` | 0 | No alerts raised |
| `findings_total` | 0 | No findings produced |

**No confirmed malicious activity is evidenced.** The authentication event described (successful auth → JWT issued → token unused within 15 minutes) is the *behavioral pattern* this detector is designed to catch. However, the detector found **no tracking records** to evaluate against, which means either:

- The token in question was never registered in `token-tracking`, or
- The table is empty because no tokens have

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
