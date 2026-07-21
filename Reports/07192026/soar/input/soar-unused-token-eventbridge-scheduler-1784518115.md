# SOAR Report - unused-token-eventbridge-scheduler-1784518115 - 2026-07-20_03-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:28:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Process Health Concern)**

**Justification:**

This event does not constitute a confirmed security incident. The detector fired as scheduled, completed its scan, and returned zero findings — meaning no unused tokens were flagged. However, the operationally significant detail is that `records_examined = 0`. This means the detector did not evaluate any token records at all, not that it evaluated records and found none suspicious.

**Confirmed evidence from the event:**

| Field | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No DynamoDB records were read during the scan |
| `matched` | 0 | No records met the unused-token filter criteria |
| `alerted` | 0 | No alerts were raised |
| `findings_total` | 0 | No findings produced |
| `trigger_source` | eventbridge-scheduler | Detector ran on schedule, not on demand |

**Critical distinction:** Zero `records_examined` is **not** evidence that no tokens exist. It is evidence that the detector either found no records to read, or that a filter, query, or scan condition returned an empty result set before evaluation could occur. This

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
