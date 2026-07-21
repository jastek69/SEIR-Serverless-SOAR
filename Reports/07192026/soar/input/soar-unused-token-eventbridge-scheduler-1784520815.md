# SOAR Report - unused-token-eventbridge-scheduler-1784520815 - 2026-07-20_04-13-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:13:35Z
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

The detector fired as scheduled and completed its run without error. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records** at the time of evaluation — not that records were examined and none matched the unused-token criteria. This is a fundamental distinction: the detector did not find suspicious tokens and suppress them; it found nothing to evaluate at all.

**Confirmed evidence from this event:**

- The `unused_token_detector` Lambda was invoked successfully by EventBridge Scheduler.
- The DynamoDB table `token-tracking` returned zero records to the detector at scan/query time.
- No alerts were raised, which is consistent with zero records examined.
- The detector correctly handles both `status` (lowercase) and legacy `Status` (uppercase) field formats, so a status field casing mismatch is not the cause of zero records.

**What this event does NOT confirm:**

- It does not confirm that a real user authenticated and received a JWT that went unused. The security event description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the *class of

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
