# SOAR Report - unused-token-eventbridge-scheduler-1784528615 - 2026-07-20_06-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:23:35Z
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

**Justification based on confirmed evidence only:**

The detector fired as scheduled via EventBridge Scheduler. It examined zero records and matched zero records. No alerts were raised, and no findings were produced. There is no confirmed evidence of a malicious authentication event, a compromised credential, or an active threat actor in this telemetry.

The scenario description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *intended detection target* of this detector — it does not represent a confirmed finding from this specific invocation. The detector returned `records_examined: 0`, meaning it found no eligible records to evaluate at all. This is a distinct outcome from finding records and determining they were unused.

**Why this is not a High or Critical finding:**

Elevating severity based on a hypothetical attack path — such as token harvesting or credential stuffing — when the detector produced zero findings would be analytically unsound. The evidence does not support it. The operational concern here is narrower and more precise: *why did the detector examine zero records?* That question has a known, non-malicious answer rooted in the implementation facts provided, which is addressed in Section 2.

**

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
