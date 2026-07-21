# SOAR Report - unused-token-eventbridge-scheduler-1784514815 - 2026-07-20_02-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:33:35Z
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
# Security Event Analysis: Unused JWT Token Detection

---

## 1. Severity Assessment

**Assessed Severity: INFORMATIONAL / LOW (Pending Triage)**

**Justification:**

The detector fired as designed — an EventBridge Scheduler invocation examined one record and matched one record against the unused-token threshold of 15 minutes. However, `alerted: 0` and `findings_total: 0` indicate that **no alert was ultimately raised and no finding was emitted**. This is a confirmed pipeline execution with a null output, not a confirmed security incident.

The critical distinction here is between a *detector run that found nothing actionable* and a *detector run that silently failed to find something it should have*. Based solely on the supplied evidence, the former is the more defensible interpretation. There are no confirmed indicators of compromise, no confirmed authentication anomalies beyond the unused token pattern itself, and no lateral movement, privilege escalation, or data access events in scope.

**What is confirmed by evidence:**
- Authentication succeeded and a JWT was issued (Cognito ID token).
- The token was not used within the 15-minute threshold window.
- The detector examined exactly one record and matched it.
- Despite the match, zero findings and zero alerts were produced.

**What is not confirmed (hypothetical):**
- Credential theft or

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
