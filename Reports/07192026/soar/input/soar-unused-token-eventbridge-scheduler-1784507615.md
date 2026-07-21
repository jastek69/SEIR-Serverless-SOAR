# SOAR Report - unused-token-eventbridge-scheduler-1784507615 - 2026-07-20_00-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:33:35Z
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

**Severity: INFORMATIONAL (with a conditional escalation path to LOW)**

### Justification

The confirmed evidence from this event is narrow and must be read precisely:

| Evidence Item | Confirmed? |
|---|---|
| Detector was invoked by EventBridge Scheduler | ✅ Yes |
| DynamoDB table `token-tracking` was queried | ✅ Implied (detector ran to completion) |
| Records were found in the table | ❌ No — `records_examined: 0` |
| Any token matched the unused-within-15-minutes threshold | ❌ No — `matched: 0` |
| Any alert was raised | ❌ No — `alerted: 0` |
| A real user authentication event occurred and was untracked | ⚠️ Unknown — not confirmed by this event |

The event itself represents a **clean detector run with no findings**. There is no confirmed malicious activity, no confirmed authentication anomaly, and no confirmed token misuse. Assigning a higher severity based solely on the possibility that tokens exist outside the tracking scope would be assigning severity to a hypothetical, which this analysis explicitly avoids.

**However**,

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
