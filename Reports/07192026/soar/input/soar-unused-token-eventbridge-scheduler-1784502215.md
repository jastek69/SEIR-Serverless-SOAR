# SOAR Report - unused-token-eventbridge-scheduler-1784502215 - 2026-07-19_23-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:03:35Z
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

The event contains **zero confirmed threat indicators**. No token was flagged as unused, no alert was raised, and no suspicious authentication pattern was confirmed. The detector ran successfully and returned clean results — but the `records_examined: 0` finding introduces a **process-integrity concern** that must be distinguished clearly from a threat finding.

| Evidence Type | Finding |
|---|---|
| Confirmed evidence | Detector invoked successfully via EventBridge Scheduler |
| Confirmed evidence | DynamoDB table `token-tracking` returned zero records to examine |
| Confirmed evidence | No tokens matched the unused-within-15-minutes threshold |
| Confirmed evidence | No alerts were generated |
| Implementation concern | Zero records examined may indicate a registration gap, not a clean environment |
| Hypothetical threat | An attacker obtained a token that was never registered and therefore never monitored |

**Critical distinction:** `records_examined: 0` does not confirm that no tokens exist in Cognito. It confirms that no tokens were registered in the `token-tracking` DynamoDB table at the time of evaluation. These are not equivalent statements. The detector can only

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
