# SOAR Report - unused-token-eventbridge-scheduler-1784519315 - 2026-07-20_03-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:48:35Z
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

**Severity: INFORMATIONAL (Not a confirmed security incident)**

**Justification:**

The detector fired as scheduled and completed successfully. The fields `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0` are internally consistent — the detector examined zero records and found zero anomalies. This is not a contradiction; it is a coherent outcome that reflects the state of the DynamoDB `token-tracking` table at the time of invocation.

**Confirmed evidence from the event:**
- The `unused_token_detector` Lambda was invoked correctly by the EventBridge Scheduler.
- The detector ran to completion without error (it produced a structured result, not an exception).
- The DynamoDB `token-tracking` table returned zero records to the detector's query/scan at the time of execution.
- No tokens were flagged, alerted, or found anomalous.

**Critical architectural constraint (confirmed from implementation facts):**
The `token-tracking` table is populated only by two mechanisms:
1. **Synthetic markers** inserted for testing/validation purposes.
2. **Explicitly registered Cognito ID tokens** from `mfa_bootstrap.py --track

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
