# SOAR Report - unused-token-eventbridge-scheduler-1784523815 - 2026-07-20_05-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:03:35Z
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

The event contains **zero confirmed security findings**. The detector fired on schedule, examined zero records, matched zero records, and raised zero alerts. No authentication anomaly, token misuse, or credential abuse has been confirmed by the available evidence.

The sole confirmed observation is a **coverage gap**: the detector examined no records, which means either the DynamoDB `token-tracking` table contained no trackable entries at invocation time, or the population of tokens eligible for tracking was never written to the table in the first place. This is an **operational and detection-hygiene concern**, not an active security incident.

**Why this cannot be escalated beyond Informational on current evidence alone:**

- There is no evidence of a real user authenticating and receiving a JWT that went unused. The event description ("User authenticated successfully / JWT token issued / Token never used within 15 minutes") describes the *class of event* the detector is designed to catch, not a confirmed instance of it.
- `records_examined: 0` means the detector had no data to evaluate. It did not find unused tokens and suppress them — it found nothing to evaluate at all.
- Assigning a higher severity based

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
