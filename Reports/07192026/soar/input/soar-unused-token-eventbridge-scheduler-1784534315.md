# SOAR Report - unused-token-eventbridge-scheduler-1784534315 - 2026-07-20_07-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:58:35Z
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

**Severity: INFORMATIONAL (with a process-integrity flag warranting investigation)**

### Justification

The event contains **zero confirmed security findings**. No token was flagged as unused, no alert was raised, and no matched records were returned. The detector ran successfully and produced a clean result. Assigning a threat-level severity to this event based on hypothetical attack paths would be analytically unsound and would inflate alert fatigue.

However, the `records_examined: 0` value introduces a **process-integrity concern** that must be distinguished from a threat finding:

| Dimension | Assessment |
|---|---|
| Confirmed threat indicators | None |
| Confirmed malicious activity | None |
| Confirmed authentication anomaly | None |
| Process integrity concern | **Yes — zero records examined warrants explanation** |
| Detector health confidence | **Reduced — cannot confirm the detector had data to evaluate** |

The scenario described in the event header ("User authenticated successfully → JWT token issued → Token never used within 15 minutes") is the **intended detection target** of this detector. The fact that `records_examined: 0` means either: (a) no tokens were registered in the tracking table at the time of the scan, or (b

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
