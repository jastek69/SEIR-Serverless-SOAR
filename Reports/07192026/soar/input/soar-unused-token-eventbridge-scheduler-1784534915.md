# SOAR Report - unused-token-eventbridge-scheduler-1784534915 - 2026-07-20_08-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T08:08:35Z
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

| Evidence Element | Status |
|---|---|
| Successful authentication | Confirmed |
| JWT token issued | Confirmed |
| Token unused within 15 minutes | Confirmed trigger condition |
| Token present in DynamoDB `token-tracking` table | **Not confirmed** |
| Malicious intent or unauthorized access | **Not confirmed — hypothetical** |
| Detector malfunction | **Not confirmed — possible** |

The detector examined **zero records** (`records_examined: 0`) and matched **zero records** (`matched: 0`). This is the most operationally significant finding in the entire event payload. A detector that fires on schedule but finds nothing to examine cannot confirm that the authentication event it was intended to monitor is actually being tracked. The zero-record result does not prove that a threat exists, nor does it prove the system is healthy — it proves only that the DynamoDB `token-tracking` table contained no records visible to the detector at scan time.

Assigning a severity of MEDIUM or higher based on the authentication event alone would require evidence that the issued

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
