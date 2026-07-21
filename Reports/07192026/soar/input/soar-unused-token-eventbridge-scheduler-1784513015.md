# SOAR Report - unused-token-eventbridge-scheduler-1784513015 - 2026-07-20_02-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:03:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run successfully. The critical finding is not a threat indicator — it is an **operational gap**: `records_examined: 0` means the DynamoDB table `token-tracking` contained **zero records at scan time**, which means the detector had nothing to evaluate. No tokens were flagged, alerted, or found anomalous.

| Evidence Item | Status | Confidence |
|---|---|---|
| Detector invoked by EventBridge Scheduler | Confirmed | High |
| Detector completed without error | Confirmed | High |
| DynamoDB table `token-tracking` returned 0 records | Confirmed | High |
| A real Cognito JWT was issued and unused | Unconfirmed | Unknown |
| An attacker harvested or misused the token | Hypothetical | No evidence |

**Critical distinction:** The event description states "User authenticated successfully, JWT token issued, token never used within 15 minutes." This describes the *intended detection scenario* — the class of event this detector is designed to catch. However, the detector examined **zero records**, which

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
