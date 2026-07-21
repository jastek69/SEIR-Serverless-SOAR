# SOAR Report - unused-token-eventbridge-scheduler-1784501943 - 2026-07-19_22-59-03_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T22:59:03Z
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

**Severity: INFORMATIONAL (with operational monitoring gap warranting LOW-severity follow-up)**

### Justification

The event contains **zero confirmed security findings**. The detector fired as scheduled, examined zero records, matched zero records, and issued zero alerts. There is no confirmed evidence of:

- A malicious actor obtaining and staging a JWT token
- A credential stuffing or token harvesting attack
- An authentication bypass or session hijacking attempt
- Any anomalous user behavior

The scenario described in the prompt preamble — "user authenticated successfully, JWT token issued, token never used within 15 minutes" — describes the **intended detection target** of this detector, not a confirmed observation from this specific invocation. The detector found no such records to evaluate.

**The operational concern that does warrant LOW-severity attention is this:** `records_examined: 0` means the DynamoDB table `token-tracking` either contained no eligible records at scan time, or the detector's query/filter logic returned an empty result set before evaluation. This is a **detection gap**, not a security incident. If legitimate Cognito ID tokens are being issued and not reaching the tracking table, the detector is operating blind.

**Severity escalation criteria** (not currently met, but defined for

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
