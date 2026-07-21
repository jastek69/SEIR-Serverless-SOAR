# SOAR Report - unused-token-eventbridge-scheduler-1784522315 - 2026-07-20_04-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:38:35Z
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

**Severity: INFORMATIONAL (with operational flag for investigation)**

**Justification:**

The detector fired as scheduled and completed without error. All quantitative findings are zero: `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0`. There is **no confirmed malicious activity, no confirmed policy violation, and no confirmed unused token** in this event.

The severity is held at **Informational** rather than elevated because:

- The detector itself produced no findings. Elevating severity based on the absence of data would conflate an operational gap with a threat finding, which violates sound incident triage discipline.
- The security event description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the **intended detection scenario** the detector is designed to catch — but the detector examined **zero records**, meaning it found no registered tokens to evaluate against that scenario.
- The confirmed risk is therefore **operational**: the detection pipeline may not be ingesting the tokens it is supposed to monitor, which is a coverage gap, not a confirmed attack.

**What is confirmed by evidence:**
- The EventBridge Scheduler triggered the Lambda function successfully.
- The Lambda function ran and returned structured output.

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
