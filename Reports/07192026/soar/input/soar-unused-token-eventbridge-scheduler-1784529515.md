# SOAR Report - unused-token-eventbridge-scheduler-1784529515 - 2026-07-20_06-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:38:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not an Active Security Incident)**

**Justification:**

The event as reported contains **zero confirmed security findings**. The detector fired on schedule, examined zero records, matched zero records, and raised zero alerts. There is no confirmed evidence of a malicious actor, a compromised credential, or an exploited token. Assigning a higher severity based solely on the hypothetical scenario of "token issued but never used" would be inappropriate given the actual telemetry returned.

However, the event does expose a **confirmed operational gap** that carries a **low-to-medium risk posture** for the following evidence-based reasons:

| Observation | Confirmed? | Risk Implication |
|---|---|---|
| `records_examined: 0` despite a scheduled invocation | **Confirmed** | The detector cannot detect what it cannot see. If tokens exist but are not registered, the detector provides false assurance. |
| Token tracking is **opt-in** via `--track-token` flag | **Confirmed** | Any Cognito client not using `mfa_bootstrap.py --track-token` is invisible to this detector. |
| Only synthetic markers and explicitly registered tokens are

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
