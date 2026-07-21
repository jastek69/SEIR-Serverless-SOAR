# SOAR Report - unused-token-eventbridge-scheduler-1784510015 - 2026-07-20_01-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:13:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 2
- Active-Unused Records Matched: 2
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Detector Invocation

---

## 1. Severity Assessment

**Assessed Severity: INFORMATIONAL / LOW (No Active Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed a full examination cycle. Two records were examined, two matched the query filter, zero alerts were raised, and zero findings were produced. This is a **nominal execution result**, not an anomalous one.

The security event described in the preamble — "user authenticated, JWT issued, token never used within 15 minutes" — is the *class of behavior* this detector is designed to catch. However, the JSON context confirms that **no such finding was surfaced in this specific invocation**. The `findings_total: 0` and `alerted: 0` fields are confirmed evidence of a clean run, not a suppressed or missed alert.

**Critical distinction between confirmed evidence and hypothetical threat:**

| Layer | Status |
|---|---|
| Detector executed successfully | ✅ Confirmed |
| Records examined: 2 | ✅ Confirmed |
| Records matched filter: 2 | ✅ Confirmed |
| Alerts raised: 0 | ✅ Confirmed |
| Findings produced: 0 | ✅

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
