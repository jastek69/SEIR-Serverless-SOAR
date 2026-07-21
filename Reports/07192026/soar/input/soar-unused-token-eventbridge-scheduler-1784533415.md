# SOAR Report - unused-token-eventbridge-scheduler-1784533415 - 2026-07-20_07-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:43:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its scan without error. The critical finding is not a threat indicator — it is an **operational gap**: `records_examined: 0` means the DynamoDB table `token-tracking` contained no records at scan time, which means the detector had nothing to evaluate. No tokens were flagged, no alerts were raised, and no confirmed malicious activity is present in this event.

**Confirmed evidence from this event:**
- The detector executed successfully and returned a clean result set.
- Zero records were present in the `token-tracking` table at scan time.
- The detector correctly handled the empty table without error.

**What this event does NOT confirm:**
- It does not confirm that no Cognito JWT tokens were issued and left unused. It confirms only that no tokens were *registered* in the `token-tracking` table.
- It does not confirm that the authentication and token-issuance pipeline is functioning end-to-end with tracking enabled.
- It does not confirm a breach, a bypass, or a misconfiguration in Cognito itself.

**Risk trade-off:** The severity

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
