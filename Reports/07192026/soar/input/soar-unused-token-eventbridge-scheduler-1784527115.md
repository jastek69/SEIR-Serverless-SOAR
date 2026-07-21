# SOAR Report - unused-token-eventbridge-scheduler-1784527115 - 2026-07-20_05-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:58:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that eligible records were examined and none matched the unused-token criteria.

This distinction is essential. The event does not confirm that a user authenticated, received a JWT, and that token went unused. The scenario described in the prompt ("User authenticated successfully, JWT token issued, Token never used within 15 minutes") represents the **intended detection target** of this detector, not a confirmed finding from this specific invocation. The detector returned `findings_total: 0` and `alerted: 0`, which is consistent with an empty tracking table at scan time.

**No severity escalation is warranted based solely on this invocation.** Escalation would be appropriate only if:

- Records were confirmed to exist in `token-tracking` and the detector failed to examine them (a detection gap), or
- A pattern of zero-record scans was confirmed to coincide with known authentication activity that should have

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
