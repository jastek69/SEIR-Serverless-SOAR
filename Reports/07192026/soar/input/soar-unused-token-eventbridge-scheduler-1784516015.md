# SOAR Report - unused-token-eventbridge-scheduler-1784516015 - 2026-07-20_02-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:53:35Z
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

The detector fired as scheduled and completed without error. All quantitative findings are zero: `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0`. There is no confirmed evidence of a malicious unused token, no confirmed evidence of a compromised credential, and no confirmed evidence of an attacker-controlled session.

The security event described in the prompt header — "User authenticated successfully, JWT token issued, token never used within 15 minutes" — is the *intended detection target* of this detector, not a confirmed finding from this invocation. The detector examined zero records, which means it found no registered tokens to evaluate at all. The absence of matched records is not proof of a clean environment; it is proof that the DynamoDB table `token-tracking` contained zero qualifying records at the time of invocation.

**The operational concern that warrants investigation is the zero `records_examined` value**, not a hypothetical attacker. This could indicate:

- A registration gap (tokens are being issued but not written to `token-tracking`)
- A timing gap (tokens were written and already expired/cleaned before the scheduler ran)

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
