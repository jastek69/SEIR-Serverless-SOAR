# SOAR Report - unused-token-eventbridge-scheduler-1784512715 - 2026-07-20_01-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:58:35Z
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

The confirmed evidence from this event is narrow and must be interpreted precisely:

| Evidence Item | Status |
|---|---|
| Detector invoked successfully by EventBridge Scheduler | ✅ Confirmed |
| DynamoDB table `token-tracking` was queried | ✅ Confirmed (0 records examined) |
| Any JWT token was issued and went unused | ❌ Not confirmed |
| Any authentication anomaly occurred | ❌ Not confirmed |
| Any attacker activity occurred | ❌ Not confirmed |

The event description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of behavior* this detector is designed to catch. However, the telemetry shows `records_examined: 0`, `matched: 0`, and `alerted: 0`. **No qualifying records were present in the token store at scan time.** This is not evidence of a threat — it is evidence of a detector run that found nothing to evaluate.

Assigning a severity above INFORMATIONAL based on the hypothetical attack path of an unused token would be analytically incorrect given the

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
