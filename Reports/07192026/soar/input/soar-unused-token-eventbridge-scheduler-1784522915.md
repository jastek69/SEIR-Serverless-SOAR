# SOAR Report - unused-token-eventbridge-scheduler-1784522915 - 2026-07-20_04-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:48:35Z
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

**Assessed Severity: INFORMATIONAL (with a conditional escalation path to LOW)**

### Justification

The event contains **zero confirmed security findings**. The detector fired on schedule, examined zero records, matched zero records, and issued zero alerts. No JWT token was observed sitting unused. No authentication anomaly was confirmed. The scenario described in the prompt preamble — "user authenticated successfully, JWT token issued, token never used within 15 minutes" — is the **intended detection hypothesis** this detector is designed to surface, not a confirmed observation from this specific invocation.

The critical distinction is:

| Dimension | Status |
|---|---|
| Detector executed | ✅ Confirmed |
| Records examined | 0 — Confirmed |
| Unused tokens found | 0 — Confirmed |
| Authentication anomaly confirmed | ❌ Not confirmed |
| Attack in progress | ❌ Not confirmed |

The conditional escalation path to LOW exists because `records_examined: 0` is itself an operational signal. If tokens are being issued by Cognito and the tracking table is expected to contain records at the time of invocation, then zero records examined may indicate a **registration gap** — tokens are being issued but never written to

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
