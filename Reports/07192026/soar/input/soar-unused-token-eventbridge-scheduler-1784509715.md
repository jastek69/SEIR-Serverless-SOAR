# SOAR Report - unused-token-eventbridge-scheduler-1784509715 - 2026-07-20_01-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:08:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 2
- Active-Unused Records Matched: 2
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Detector Invocation

---

## 1. Severity Assessment

**Assessed Severity: INFORMATIONAL / LOW (No Active Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed a full examination cycle. The event reports:

- `records_examined: 2` — the detector found and evaluated two records in the DynamoDB `token-tracking` table.
- `matched: 2` — both records matched the detector's filter criteria (e.g., status field recognized, token age calculable).
- `alerted: 0` — neither record triggered an alert condition.
- `findings_total: 0` — no unused tokens were identified within the 15-minute threshold window.
- `findings_sample: []` — no evidence of anomalous authentication behavior.

**The detector is operating correctly.** Both records were examined and cleared. There is no confirmed evidence of a threat, a detection gap, or an authentication anomaly in this invocation. Severity is informational because the event documents a healthy scheduled control execution, not a security finding.

**Important distinction:** The security event described in the prompt header ("User authenticated successfully → JWT token issued → Token never used within 15 minutes") describes the *class of behavior* this detector is designed to catch. In this specific

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
