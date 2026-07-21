# SOAR Report - unused-token-eventbridge-scheduler-1784504915 - 2026-07-19_23-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:48:35Z
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

**Severity: INFORMATIONAL (with a process-integrity flag warranting investigation)**

### Justification

The event contains **zero confirmed threat indicators**. No authentication anomaly, no token misuse, no lateral movement, and no data exfiltration signal is present in the supplied evidence. The detector fired as scheduled, completed without error, and returned zero findings — which is a valid operational outcome when no tokens are currently registered in the tracking table.

However, the event warrants a **process-integrity flag** — not a threat-based severity escalation — for the following confirmed reason drawn directly from the implementation facts:

> *"The bootstrap/test flow links Cognito jti to usage when `--track-token` is used; other Cognito clients are not automatically registered."*

This means the detector's scope is **structurally limited by design**. The zero-records result could mean:
- (a) No tokens were registered via `mfa_bootstrap.py --track-token` in the last 15 minutes (benign, expected), **or**
- (b) Real Cognito JWT tokens were issued to production users but were never registered in the `token-tracking` DynamoDB table, making them **invisible to the detector entirely**.

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
