# SOAR Report - unused-token-eventbridge-scheduler-1784534615 - 2026-07-20_08-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T08:03:35Z
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

**Severity: INFORMATIONAL (with a conditional LOW flag pending coverage verification)**

### Justification

The event contains **zero confirmed threat indicators**. No tokens were examined, no tokens matched the unused-within-15-minutes threshold, and no alerts were generated. The detector fired on schedule via EventBridge Scheduler and completed its run — this is operationally normal behavior for a scheduled Lambda invocation against an empty or unpopulated dataset.

**Confirmed evidence from the event:**

| Field | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No records were present in or returned from the DynamoDB `token-tracking` table at scan time |
| `matched` | 0 | No filter conditions were evaluated against any record |
| `alerted` | 0 | No downstream alerting was triggered |
| `findings_total` | 0 | No findings were produced |
| `findings_sample` | `[]` | Empty — consistent with zero records examined |

**Critical distinction:** Zero matched records is a statement about what the detector found in the `token-tracking` table at the moment of invocation. It is **not** evidence that the DynamoDB table is functioning correctly, that

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
