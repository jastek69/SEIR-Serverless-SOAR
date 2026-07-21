# SOAR Report - unused-token-eventbridge-scheduler-1784535515 - 2026-07-20_08-18-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T08:18:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not a Confirmed Security Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed without error. The critical finding is not a malicious event — it is an **operational coverage gap**: `records_examined: 0` means the detector examined no token records whatsoever. This is confirmed evidence of a tracking registration gap, not confirmed evidence of an attack.

The scenario described in the prompt header — "User authenticated successfully, JWT token issued, token never used within 15 minutes" — is the **intended detection target**. However, the detector cannot surface that pattern if the token was never registered in the `token-tracking` DynamoDB table in the first place.

**Why this is not elevated to Medium or High:**

- There are zero matched records, zero alerts, and zero findings. Elevating severity based purely on the hypothetical attack path (credential harvesting, token theft, automated issuance abuse) would be assigning severity to a threat model, not to confirmed evidence.
- The authentication event and JWT issuance are described generically. No anomalous authentication indicators (impossible travel, unfamiliar device, brute-force precursor, MFA

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
