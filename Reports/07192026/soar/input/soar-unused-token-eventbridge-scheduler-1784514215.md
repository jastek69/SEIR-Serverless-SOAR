# SOAR Report - unused-token-eventbridge-scheduler-1784514215 - 2026-07-20_02-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:23:35Z
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

The detector fired as scheduled and completed its run without error. The core metrics are unambiguous:

| Metric | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No token-tracking records existed in DynamoDB at scan time |
| `matched` | 0 | No records met the unused-token filter criteria |
| `alerted` | 0 | No alerts were raised |
| `findings_total` | 0 | No findings produced |

**Confirmed evidence** from the event context establishes that the detector executed successfully via EventBridge Scheduler and queried the `token-tracking` DynamoDB table. The result of zero records examined is not evidence of a missed threat — it is evidence that the table contained no qualifying records at the time of the scan. Per the implementation facts, tracking records are only written when `mfa_bootstrap.py --track-token` is explicitly invoked, or when synthetic markers are inserted. No such records were present.

**Critical distinction:** Zero matched records means the filter found nothing to match against. It does not mean the detector malfunctioned, that Dynam

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
