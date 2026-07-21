# SOAR Report - unused-token-eventbridge-scheduler-1784533715 - 2026-07-20_07-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:48:35Z
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

**Assessed Severity: INFORMATIONAL (with a conditional LOW advisory)**

**Justification based on confirmed evidence only:**

The detector fired as scheduled via EventBridge Scheduler. It examined zero records and matched zero records. No alerts were raised, and no findings were produced. There is no confirmed evidence of a malicious authentication event, a compromised credential, or an exploited token in this invocation.

The scenario description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of event* this detector is designed to catch — it does not represent a confirmed finding from this specific invocation. The JSON payload explicitly shows `records_examined: 0`, `matched: 0`, and `alerted: 0`.

**Why not higher severity:**
Assigning a severity of MEDIUM or HIGH based on the described scenario would require at least one matched record in `findings_sample`. None exist. Escalating severity from a hypothetical attack path when the detector produced zero findings would generate false urgency and erode analyst trust in the alerting pipeline.

**The conditional LOW advisory** applies not to an attack but to a **detection gap**: the fact that `records_examined` is zero when a real authentication event may have occurred suggests the token

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
