# SOAR Report - unused-token-eventbridge-scheduler-1784516615 - 2026-07-20_03-03-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:03:35Z
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

**Assessed Severity: INFORMATIONAL (with a conditional LOW flag pending coverage verification)**

### Justification

The detector fired as scheduled and completed without error. All quantitative findings fields — `records_examined`, `matched`, `alerted`, and `findings_total` — are zero. There are no confirmed malicious indicators, no anomalous authentication patterns, and no evidence of token misuse in the supplied event context.

**The critical observation is not what the detector found, but what it examined.** Zero `records_examined` means the DynamoDB table `token-tracking` contained no records at query time that matched the detector's filter criteria. This is architecturally expected given the confirmed implementation fact: only tokens explicitly registered via `mfa_bootstrap.py --track-token` or synthetic test markers are written to the tracking table. Cognito tokens issued through any other client path are never registered and therefore cannot be examined.

**Confirmed evidence:**
- Detector invoked successfully by EventBridge Scheduler.
- DynamoDB table `token-tracking` returned zero qualifying records.
- No alerts were raised because no anomalies were found within the examined population.

**Implementation defect (confirmed, not hypothetical):**
- Token tracking coverage is explicitly partial

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
