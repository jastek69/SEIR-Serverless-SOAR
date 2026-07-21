# SOAR Report - unused-token-eventbridge-scheduler-1784526815 - 2026-07-20_05-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:53:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records** at the time of evaluation — not that records existed and were filtered out. `matched: 0` and `alerted: 0` are direct downstream consequences of that empty examination set, not independent signals.

There is **no confirmed evidence** of:
- A malicious actor obtaining and staging a JWT token
- A token being issued and deliberately withheld from use to evade detection
- A compromise of the Cognito identity pool or token issuance pipeline
- Any anomalous authentication behavior

The event does, however, expose a **confirmed implementation gap**: the detector can only evaluate tokens that were explicitly registered via `mfa_bootstrap.py --track-token`. Cognito JWT tokens issued through any other client path are **not automatically registered** in the `token-tracking` table. This means the detector's coverage is structurally incomplete, and the zero-record result may reflect a registration gap rather than a genuine absence of issued tokens.

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
