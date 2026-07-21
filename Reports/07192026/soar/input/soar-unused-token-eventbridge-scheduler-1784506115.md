# SOAR Report - unused-token-eventbridge-scheduler-1784506115 - 2026-07-20_00-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:08:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical finding is not a malicious event but a **detection coverage gap**: `records_examined: 0` means the DynamoDB table `token-tracking` contained no records at the time of evaluation — neither synthetic markers nor explicitly registered Cognito ID tokens.

| Evidence Type | Finding |
|---|---|
| **Confirmed (evidence-based)** | Detector ran successfully; zero records were present in `token-tracking` at scan time |
| **Confirmed (evidence-based)** | No tokens were flagged, alerted, or found — because there was nothing to evaluate |
| **Confirmed (implementation fact)** | Only tokens registered via `mfa_bootstrap.py --track-token` are tracked; other Cognito clients are not automatically registered |
| **Implementation defect** | The absence of synthetic markers suggests the health/canary marker population step may not be running, or markers are expiring before the detector runs |
| **Hypothetical** | A real unused token could exist in Cognito but be invisible to this detector because it

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
