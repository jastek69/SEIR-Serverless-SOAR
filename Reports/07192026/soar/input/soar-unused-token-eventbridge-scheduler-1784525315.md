# SOAR Report - unused-token-eventbridge-scheduler-1784525315 - 2026-07-20_05-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:28:35Z
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

The confirmed evidence from this event is narrow and must be read precisely:

| Evidence Item | Status |
|---|---|
| Detector invoked successfully by EventBridge Scheduler | **Confirmed** |
| DynamoDB table `token-tracking` was queried | **Confirmed** |
| Zero records were examined (`records_examined: 0`) | **Confirmed** |
| Zero matches, zero alerts, zero findings | **Confirmed** |
| A user authenticated and received a JWT that went unused | **Stated trigger context — not directly corroborated by DynamoDB data** |

The critical distinction here is that **the detector found nothing to examine, not that it examined records and found no anomalies.** `records_examined: 0` means the DynamoDB table either contained no qualifying records at query time, or the query filter returned an empty result set before any record-level evaluation occurred. This is not the same as "the system checked and everything is fine."

The stated security event — a user authenticated, a JWT was issued, and the token was never used within 15 minutes — **cannot be confirmed or denied by this detector

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
