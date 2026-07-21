# SOAR Report - unused-token-eventbridge-scheduler-1784505215 - 2026-07-19_23-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:53:35Z
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

| Evidence Element | Confirmed? | Notes |
|---|---|---|
| Successful authentication occurred | **Not confirmed by this event** | The event description is a framing scenario; the detector itself found nothing |
| JWT token issued | **Not confirmed by this event** | Same caveat — no records in DynamoDB corroborate this |
| Token unused within 15 minutes | **Not confirmed** | Zero records examined means no tracked tokens were present to evaluate |
| Detector executed successfully | **Confirmed** | EventBridge Scheduler triggered the Lambda; it ran and returned findings_total: 0 |
| DynamoDB table queried | **Confirmed by implication** | records_examined: 0 means the query returned an empty result set, not that the query failed |

The critical distinction here is that **`records_examined: 0` is not evidence of a threat — it is evidence of an empty or unregistered tracking dataset.** No unused tokens were found because no tokens were registered for tracking in the `token-tracking` DynamoDB table at the time

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
