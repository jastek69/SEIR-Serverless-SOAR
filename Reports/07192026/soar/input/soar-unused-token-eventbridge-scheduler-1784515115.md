# SOAR Report - unused-token-eventbridge-scheduler-1784515115 - 2026-07-20_02-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:38:35Z
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

The detector fired as designed — an EventBridge Scheduler invocation examined one record and matched one record against the unused-token threshold of 15 minutes. However, `alerted: 0` and `findings_total: 0` indicate that **no alert was ultimately raised and no findings were emitted**. This is a confirmed pipeline execution with a null output, not a confirmed security incident.

| Evidence Item | Status |
|---|---|
| Successful authentication + JWT issuance | Confirmed |
| Token unused within 15-minute window | Confirmed (1 record matched threshold) |
| Alert raised | Not confirmed — `alerted: 0` |
| Finding generated | Not confirmed — `findings_total: 0` |
| Malicious activity | Hypothetical — no supporting evidence |
| Credential theft or token harvesting | Hypothetical — no supporting evidence |

**Critical observation:** The mismatch between `matched: 1` and `alerted: 0` / `findings_total: 0` is the primary analytical concern. A record met the detection criterion but produced no downstream output. This is either an intentional supp

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
