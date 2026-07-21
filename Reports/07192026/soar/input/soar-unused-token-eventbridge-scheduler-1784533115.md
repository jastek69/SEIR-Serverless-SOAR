# SOAR Report - unused-token-eventbridge-scheduler-1784533115 - 2026-07-20_07-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:38:35Z
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

| Evidence Element | Confirmed? |
|---|---|
| Successful authentication occurred | **Assumed from event description** — not directly confirmed by detector output |
| JWT token was issued | **Assumed from event description** — not confirmed by detector output |
| Token unused within 15-minute threshold | **Not confirmed** — detector examined zero records |
| Malicious activity | **Not confirmed** — no findings |
| Detector failure | **Not confirmed** — zero records examined is a data population result, not a detector fault signal |

The detector ran successfully as triggered by EventBridge Scheduler. It examined zero records (`records_examined: 0`) and produced zero matches (`matched: 0`), zero alerts (`alerted: 0`), and zero findings (`findings_total: 0`). **This is not evidence of an attack, a missed detection, or a system failure.** It is evidence that the DynamoDB table `token-tracking` contained no records that satisfied the detector's filter criteria at the time of invocation.

The critical nuance here is the **tracking

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
