# SOAR Report - unused-token-eventbridge-scheduler-1784518415 - 2026-07-20_03-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:33:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that eligible records were examined and none matched. This is a confirmed implementation observation, not a confirmed security finding.

No JWT tokens were flagged as unused. No alerts were raised. No confirmed malicious activity is evidenced by this event.

**Why this is not elevated to MEDIUM or higher:**

The event description states "User authenticated successfully, JWT token issued, token never used within 15 minutes." However, the detector's own telemetry (`records_examined: 0`, `matched: 0`, `alerted: 0`) does not confirm that this specific authentication event was tracked, evaluated, or found suspicious. The gap between the narrative description and the detector output is itself the primary finding — a **detection coverage gap**, not a confirmed threat.

Elevating severity based on the hypothetical attack path (e.g., credential harvesting, token theft) without a matched record or corroborating

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
