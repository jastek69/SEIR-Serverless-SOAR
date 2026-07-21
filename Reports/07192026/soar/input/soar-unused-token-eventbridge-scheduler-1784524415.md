# SOAR Report - unused-token-eventbridge-scheduler-1784524415 - 2026-07-20_05-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:13:35Z
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

**Assessed Severity: INFORMATIONAL (Not a confirmed security incident)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The core finding is `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0`. This means the detector found **no records in the DynamoDB `token-tracking` table to evaluate** — it did not find unused tokens and suppress them, nor did it encounter tokens and clear them. It examined nothing.

**Confirmed evidence from the event:**
- The detector invocation itself succeeded (EventBridge triggered it, Lambda ran, results were returned in structured form).
- Zero records were present in or returned from the `token-tracking` table at the time of evaluation.
- No alerts were raised because there was nothing to alert on.

**Critical distinction:** The absence of findings here is **not equivalent to a clean bill of health for the broader authentication surface**. It is a statement about the contents of one DynamoDB table at one point in time. The detector only tracks tokens that were **explicitly registered** via `mfa_bootstrap.py --track-token` or synthetic test markers. The vast majority of Cognito

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
