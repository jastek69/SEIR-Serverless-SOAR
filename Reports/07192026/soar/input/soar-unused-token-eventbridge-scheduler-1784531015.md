# SOAR Report - unused-token-eventbridge-scheduler-1784531015 - 2026-07-20_07-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:03:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Process Health Alert)**

**Justification based on confirmed evidence only:**

| Evidence Item | Confirmed? | Source |
|---|---|---|
| Successful authentication occurred | **Not confirmed by this event** | Not present in JSON payload |
| JWT token issued | **Not confirmed by this event** | Not present in JSON payload |
| Token unused for 15 minutes | **Not confirmed by this event** | Not present in JSON payload |
| Detector invoked by EventBridge Scheduler | ✅ Confirmed | `trigger_source`, `reason` fields |
| Zero records examined | ✅ Confirmed | `records_examined: 0` |
| Zero matches, zero alerts, zero findings | ✅ Confirmed | `matched: 0`, `alerted: 0`, `findings_total: 0` |

**Critical distinction:** The scenario description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") represents the *intended detection target* of this detector — the class of event it was built to find. It is **not confirmed evidence** present in this invocation's output. The actual confirmed event is that the detector ran and found **

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
