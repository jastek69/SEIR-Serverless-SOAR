# SOAR Report - unused-token-eventbridge-scheduler-1784530715 - 2026-07-20_06-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:58:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (No Active Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records at query time** — not that records were examined and none matched the unused-token criteria. This is a confirmed implementation and operational coverage gap, not evidence of a malicious event.

| Evidence Type | Finding |
|---|---|
| **Confirmed evidence** | Detector invoked successfully; DynamoDB table returned zero records to examine |
| **Confirmed evidence** | `matched: 0`, `alerted: 0`, `findings_total: 0` are downstream consequences of `records_examined: 0` |
| **Implementation defect** | Token tracking is opt-in via `mfa_bootstrap.py --track-token`; Cognito tokens issued outside this flow are never registered |
| **Hypothetical threat** | An attacker obtaining a valid Cognito JWT would not be detected by this detector unless the token was explicitly registered |

**Why severity is not elevated:** There is no confirmed authentication anomaly,

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
