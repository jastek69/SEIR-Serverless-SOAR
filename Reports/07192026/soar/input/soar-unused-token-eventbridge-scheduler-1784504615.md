# SOAR Report - unused-token-eventbridge-scheduler-1784504615 - 2026-07-19_23-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:43:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of execution — not that eligible records were examined and none matched. This is a confirmed implementation observation, not a confirmed security finding.

No JWT tokens were flagged as unused. No alerts were raised. There is no confirmed evidence of:
- A compromised credential
- A token harvesting or replay attack
- An authentication anomaly tied to a specific user or session

**What is confirmed by the evidence:**
- The detector ran successfully and was triggered by the scheduler as expected.
- The DynamoDB table `token-tracking` returned zero records to the detector at evaluation time.
- The detector logic correctly handled the empty result set (no false positives, no crashes).

**What is NOT confirmed:**
- That all Cognito-issued JWT tokens in the environment are being tracked. The implementation facts explicitly state that only tokens registered via `mfa_bootstrap.py --track-token` are written to the token store. Standard

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
