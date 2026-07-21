# SOAR Report - unused-token-eventbridge-scheduler-1784535815 - 2026-07-20_08-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T08:23:35Z
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

The event contains **zero confirmed threat indicators**. Every quantitative field in the payload — `records_examined`, `matched`, `alerted`, `findings_total` — is zero. No JWT token was flagged as unused. No anomalous authentication behavior was detected within the scope of this invocation.

The severity ceiling is held at **INFORMATIONAL** because:

- The detector fired correctly via its scheduled EventBridge trigger, confirming the scheduling and Lambda invocation path is operational.
- The zero-record result is **not evidence of a threat**; it is evidence that the detector's filter matched nothing in the DynamoDB `token-tracking` table at the time of execution.
- There is **no confirmed authentication anomaly** in this event. The scenario description ("user authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of event* the detector is designed to catch — it does not confirm that such an event was actually recorded and processed in this invocation.

**Conditional escalation to LOW** is warranted only if investigation (see Section 3) confirms that a Cognito ID token was issued but was never registered in

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
