# SOAR Report - unused-token-eventbridge-scheduler-1784519615 - 2026-07-20_03-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:53:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (No Active Incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that eligible records were examined and none matched. This is a confirmed implementation scope boundary, not a detection gap caused by an attacker evading the detector.

The security event description states a user authenticated successfully, a JWT was issued, and the token was never used within 15 minutes. However, **no corresponding tracking record exists in DynamoDB** for that token. Based on the confirmed implementation facts, this is fully explained by the architecture: only tokens explicitly registered via `mfa_bootstrap.py --track-token` are written to the `token-tracking` table. Cognito clients that do not invoke that bootstrap flow are **not automatically registered**, and therefore their tokens are invisible to this detector.

**There is no confirmed malicious activity.** The severity elevation risk is low because:

- The authentication event itself is not anomalous (successful MFA or standard auth).
- The JWT was issued by

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
