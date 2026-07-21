# SOAR Report - unused-token-eventbridge-scheduler-1784511815 - 2026-07-20_01-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T01:43:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (No Active Threat Confirmed)**

**Justification:**

The detector fired as scheduled via EventBridge Scheduler and completed its run successfully. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records at query time** — not that records existed and were filtered out. With nothing to examine, the downstream counts (`matched: 0`, `alerted: 0`, `findings_total: 0`) are arithmetically expected and carry no independent evidentiary weight.

**Confirmed evidence from this event:**

- The detector invocation itself is healthy: it was triggered, it ran, and it produced a structured result.
- The DynamoDB table `token-tracking` returned no records to the detector at the time of execution.
- No unused tokens were identified because no tokens were registered for tracking.

**What this event does NOT confirm:**

- It does not confirm that no JWT tokens were issued by Cognito. Cognito issues tokens independently of this detector's tracking table.
- It does not confirm that all issued tokens are being tracked. The `cognito_jwt_linkage` implementation fact explicitly states that only tokens registered via `m

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
