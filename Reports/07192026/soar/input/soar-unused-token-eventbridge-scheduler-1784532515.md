# SOAR Report - unused-token-eventbridge-scheduler-1784532515 - 2026-07-20_07-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:28:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed without error. However, `records_examined: 0` means the detector found **no token tracking records in DynamoDB at scan time** — it did not find unused tokens and suppress them, nor did it encounter an error. The result is a **coverage gap**, not a confirmed attack or policy violation.

**Confirmed evidence from the event:**
- The detector ran successfully and was triggered by the scheduler as designed.
- Zero records were present in the `token-tracking` DynamoDB table at the time of invocation.
- Zero matches, zero alerts, and zero findings are consistent with an empty or unpopulated table — not with a suppressed or missed threat.

**What this is NOT (based on available evidence):**
- There is no confirmed authentication anomaly.
- There is no confirmed unused token sitting undetected in the environment.
- There is no confirmed attacker activity.

**Why this still warrants attention:**
The detector's value depends entirely on tokens being registered into DynamoDB at issuance time. If registration is not happening — due to

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
