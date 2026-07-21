# SOAR Report - unused-token-eventbridge-scheduler-1784513615 - 2026-07-20_02-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:13:35Z
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

**Severity: INFORMATIONAL (with a process-integrity flag warranting investigation)**

### Justification

The event contains **zero confirmed threat indicators**. No authentication anomaly, no credential abuse, no lateral movement, and no data exfiltration signal is present in the supplied evidence. The detector fired on schedule, completed without error, and returned `records_examined: 0`, `matched: 0`, `alerted: 0`.

However, the zero-records result is itself a **process-integrity concern** that warrants analyst attention, because the detector's value depends entirely on whether tokens are being registered into the DynamoDB `token-tracking` table in the first place. If registration is not occurring — due to a code path gap, a deployment regression, or a misconfigured bootstrap flow — the detector will always return zero records and will silently fail to catch genuinely unused tokens. That failure mode is operationally significant even though it is not a confirmed security incident.

**Key distinctions:**

| Dimension | Status |
|---|---|
| Confirmed threat activity | ❌ None |
| Confirmed authentication abuse | ❌ None |
| Confirmed detector error | ❌ None |
| Process-integrity gap (possible)

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
