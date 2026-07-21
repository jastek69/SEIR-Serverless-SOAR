# SOAR Report - unused-token-eventbridge-scheduler-1784528915 - 2026-07-20_06-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:28:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Process Health Alert)**

**Justification:**

This event does not constitute a confirmed security incident. The detector fired as scheduled, completed its scan, and returned zero records examined, zero matches, and zero alerts. There is no evidence of a malicious actor, a compromised credential, or an exploited token within this event context.

The severity is elevated from "no action required" to **LOW** solely because `records_examined: 0` indicates the detector scanned an empty or unregistered dataset. This creates a **detection coverage gap**: if legitimate Cognito JWT tokens are being issued in production but are not registered in the `token-tracking` DynamoDB table, the detector cannot flag them as unused — meaning the intended security control is operating with a blind spot rather than operating correctly.

**Critical distinction:**
- **Confirmed evidence:** The detector ran, found nothing to examine, and produced no findings. This is a pipeline health observation, not a threat finding.
- **Implementation concern (confirmed by implementation facts):** Token tracking is opt-in via `mfa_bootstrap.py --track-token`. Cognito clients that do not invoke this path are invisible to the detector.
- **Hypothetical threat:** An att

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
