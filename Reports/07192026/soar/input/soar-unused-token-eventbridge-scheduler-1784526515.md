# SOAR Report - unused-token-eventbridge-scheduler-1784526515 - 2026-07-20_05-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:48:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (No Active Threat Confirmed)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run successfully. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that zero threats were found among a populated dataset.

**Confirmed evidence from the event:**

| Field | Value | Interpretation |
|---|---|---|
| `records_examined` | 0 | No records were present or queryable in the token-tracking table at scan time |
| `matched` | 0 | No records met the unused-token filter criteria |
| `alerted` | 0 | No alerts were raised |
| `findings_total` | 0 | No findings produced |
| `findings_sample` | `[]` | Empty — consistent with zero records examined |

**Key distinction:** Zero matched records is a direct consequence of zero records examined. This is **not evidence that a threat was detected and suppressed**, nor is it evidence that the detector malfunctioned. It is evidence that the token-tracking table was empty or returned no

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
