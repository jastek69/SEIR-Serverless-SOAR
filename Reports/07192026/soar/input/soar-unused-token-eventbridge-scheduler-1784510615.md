# SOAR Report - unused-token-eventbridge-scheduler-1784510615 - 2026-07-20_01-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:23:35Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 1
- Active-Unused Records Matched: 1
- Alerts Published: 1
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- 50e3dc1d-159b-4451-b0b3-927b828e933e | user=user.test | kind=cognito-id-token | age_minutes=15 | issued_at=2026-07-20T01:07:36Z

## SOAR Analysis
# Security Event Analysis: Unused JWT Token — `user.test`

---

## 1. Severity Assessment

**Severity: LOW (Informational / Monitoring)**

**Justification:**

The confirmed evidence is narrow and specific: a single Cognito ID token (`token_id: 50e3dc1d-159b-4451-b0b3-927b828e933e`) was issued to `user.test`, registered in the `token-tracking` DynamoDB table via the `mfa_bootstrap.py --track-token` flow, and was not used within the 15-minute threshold window. The detector fired correctly, examined one record, matched one record, and issued one alert. All detector mechanics functioned as designed.

**There are no confirmed indicators of compromise.** No lateral movement, no token replay, no credential stuffing signal, no anomalous source IP, and no downstream resource access are present in the supplied evidence. The account name `user.test` is consistent with a test or synthetic identity, which materially increases the prior probability of a benign explanation (e.g., an automated test that authenticated but did not complete its usage phase).

Escalating severity based on hypothetical attack paths — such as token theft or session hijacking — would be inappropriate given zero corroborating evidence. The event is correctly classified as a low-severity

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
