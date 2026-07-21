# SOAR Report - unused-token-eventbridge-scheduler-1784508215 - 2026-07-20_00-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:43:35Z
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

The detector fired as scheduled and completed without error. The fields `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0` collectively indicate that the DynamoDB table `token-tracking` contained **zero records at query time** — not that records existed and were filtered out. This is a critical distinction.

No confirmed evidence of a threat exists in this event. The security event description ("User authenticated successfully → JWT token issued → Token never used within 15 minutes") describes the *intended detection scenario* the detector is designed to catch, but the zero-record result means the detector found **no tracked tokens at all** — it did not find an unused token and alert on it.

**Confirmed evidence from this event:**
- The EventBridge Scheduler successfully invoked the `unused_token_detector` Lambda.
- The Lambda completed its run and reported results.
- The DynamoDB table `token-tracking` returned zero records to examine.
- No alerts were generated.

**Implementation gap (confirmed, not hypothetical):**
- The `implementation_facts` explicitly state that only tokens registered via `mfa

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
