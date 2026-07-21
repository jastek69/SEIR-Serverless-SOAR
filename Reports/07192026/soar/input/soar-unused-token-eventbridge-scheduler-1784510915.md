# SOAR Report - unused-token-eventbridge-scheduler-1784510915 - 2026-07-20_01-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:28:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not an Active Threat)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed without error. However, `records_examined: 0` means the detector found **no token-tracking records in the DynamoDB table `token-tracking`** to evaluate. This is a confirmed operational observation, not a confirmed security incident.

**What the evidence confirms:**
- The detector executed successfully (it produced structured output with zero findings, not an error or crash).
- The DynamoDB table `token-tracking` contained zero records at the time of evaluation, or zero records matched the query criteria used by the detector.
- No unused tokens were flagged because no tokens were registered for tracking.

**What the evidence does NOT confirm:**
- That a real Cognito JWT was issued and went unused. The security event description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of behavior* this detector is designed to catch — it does not confirm that a specific user session triggered this run.
- That an attacker harvested a token. There is no evidence of credential theft, token replay, or lateral movement in the supplied data.

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
