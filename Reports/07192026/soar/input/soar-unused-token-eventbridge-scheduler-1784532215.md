# SOAR Report - unused-token-eventbridge-scheduler-1784532215 - 2026-07-20_07-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:23:35Z
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

**Severity: INFORMATIONAL (with operational risk flag)**

### Justification

The event contains **zero confirmed security findings**. No tokens were examined, no tokens matched the unused-within-15-minutes threshold, and no alerts were generated. There is no evidence of credential abuse, token theft, session hijacking, or authentication anomaly in this event record.

However, the `records_examined: 0` value is the analytically significant data point here. The detector fired successfully via EventBridge Scheduler, executed without error (based on the trigger completing and returning structured output), and returned a clean result set — but it examined **nothing**. This is not a security incident; it is an **operational coverage gap** that reduces the effectiveness of the detective control.

The distinction is critical:

| Dimension | Assessment |
|---|---|
| Active threat evidence | None confirmed |
| Detection logic failure | Unconfirmed — possible coverage gap |
| Token abuse in progress | No evidence |
| Control effectiveness | Degraded — scope limited to explicitly registered tokens |
| Escalation warranted | No — monitor and investigate operationally |

Elevating this to a higher severity based on hypothetical attack paths (e.g., "an attacker could have stolen

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
