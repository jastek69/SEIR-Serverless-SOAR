# SOAR Report - unused-token-eventbridge-scheduler-1784506415 - 2026-07-20_00-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:13:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not a Confirmed Security Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed without error. The critical finding is not a malicious event — it is an **operational coverage gap**: `records_examined: 0` means the detector examined no token records at all, which means it cannot confirm or deny whether any unused tokens exist in the environment.

| Evidence Item | Status | Confidence |
|---|---|---|
| Successful authentication occurred | Confirmed (stated in event) | High |
| JWT token was issued | Confirmed (stated in event) | High |
| Token was unused within 15 minutes | Confirmed (stated in event) | High |
| Detector identified this token | **Not confirmed** | None |
| DynamoDB table contains tracking records | **Unknown** | None |
| Token was registered via `--track-token` | **Unknown** | None |

The authentication and issuance are confirmed facts. The detector's inability to find anything (`records_examined: 0`) does not confirm the token is safe — it confirms the detector had **nothing to examine**. This is a detection gap, not a clean bill

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
