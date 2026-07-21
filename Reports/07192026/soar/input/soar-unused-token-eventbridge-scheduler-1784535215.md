# SOAR Report - unused-token-eventbridge-scheduler-1784535215 - 2026-07-20_08-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T08:13:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Pipeline Health Issue)**

**Justification:**

This event does not constitute a confirmed security incident. The detector fired as scheduled, examined zero records, matched zero records, and generated zero alerts. There are no confirmed indicators of compromise, no anomalous authentication patterns, and no evidence of token misuse within the supplied context.

The scenario described in the preamble — "user authenticated successfully, JWT token issued, token never used within 15 minutes" — represents the *intended detection target* of this pipeline, not a confirmed finding. The detector did not surface that pattern because it examined no records at all.

**The primary concern raised by this event is operational, not adversarial:** the detection pipeline may not be ingesting or registering tokens correctly, which would create a silent detection gap. A silent gap is a risk multiplier — it does not represent an active threat, but it degrades the organization's ability to detect one.

**Risk trade-off:** Elevating this to MEDIUM or HIGH based on hypothetical attack paths (e.g., credential stuffing, token harvesting) would be analytically unsound given zero supporting evidence. The correct posture is to treat this as a pipeline integrity issue requiring investigation before the detector can be trusted

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
