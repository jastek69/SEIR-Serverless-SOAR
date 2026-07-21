# SOAR Report - unused-token-eventbridge-scheduler-1784522015 - 2026-07-20_04-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:33:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap)**

**Justification:**

This event contains **zero confirmed security findings**. The detector fired on schedule, examined zero records, matched zero records, and issued zero alerts. There is no evidence of a malicious actor, a compromised credential, or an abused JWT token within the supplied context.

The severity is not elevated based on hypothetical attack paths. The event does, however, surface a **confirmed operational gap**: the detector is running but has no records to evaluate. This is a **coverage and instrumentation deficiency**, not an active threat.

The risk is indirect: if the token-tracking pipeline is not populating DynamoDB as intended, then the detector's protective value is zero — meaning a genuinely unused or stolen token would pass through the 15-minute window undetected and unalerted. The severity of *that* gap is **Medium** from a detection-posture standpoint, but it is not elevated to High or Critical because no attack evidence exists in this event.

**Evidence basis:**

| Field | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No records were present or queryable at scan time |
| `matched` |

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
