# SOAR Report - unused-token-eventbridge-scheduler-1784503715 - 2026-07-19_23-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:28:35Z
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

**Severity: INFORMATIONAL (Not a confirmed security incident)**

**Justification:**

The detector fired as scheduled and completed successfully. The fields `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0` are internally consistent — the detector examined zero records and produced zero findings. This is not a detection failure; it is a null result from an empty or unpopulated dataset.

**Confirmed evidence from the event:**

| Evidence | Interpretation |
|---|---|
| `records_examined: 0` | No records were present in the DynamoDB `token-tracking` table at scan time, or no records matched the query filter |
| `matched: 0` | No tokens met the unused-within-15-minutes threshold |
| `alerted: 0` | No alerts were raised, consistent with zero matches |
| `findings_total: 0` | No findings generated |
| `trigger_source: eventbridge-scheduler` | Detector ran on schedule, not in response to an anomaly |

**Critical distinction:** The scenario description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of event* this detector

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
