# SOAR Report - unused-token-eventbridge-scheduler-1784509415 - 2026-07-20_01-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:03:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 1
- Active-Unused Records Matched: 1
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Detected

---

## 1. Severity Assessment

**Assessed Severity: LOW (Informational / Monitoring)**

**Justification based on confirmed evidence only:**

| Evidence Item | Confirmed | Source |
|---|---|---|
| Successful authentication occurred | ✅ | Event description |
| JWT token was issued | ✅ | Event description |
| Token unused within 15-minute threshold | ✅ | Event description |
| `records_examined: 1` | ✅ | JSON context |
| `matched: 1` | ✅ | JSON context |
| `alerted: 0` | ✅ | JSON context |
| `findings_total: 0` | ✅ | JSON context |
| Evidence of malicious activity | ❌ | Not present |
| Evidence of credential misuse | ❌ | Not present |
| Evidence of lateral movement | ❌ | Not present |

The detector examined one record, matched it against the unused-token criteria, but produced **zero findings and zero alerts**. This is a critical distinction: the detector fired and ran successfully, but its internal logic did not escalate the event to a finding. This means either the record matched the unused-token pattern but was filtered out

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
