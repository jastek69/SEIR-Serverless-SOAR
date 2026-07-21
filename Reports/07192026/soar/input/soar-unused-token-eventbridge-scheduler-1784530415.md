# SOAR Report - unused-token-eventbridge-scheduler-1784530415 - 2026-07-20_06-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:53:35Z
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

The detector fired as scheduled and completed its run without error. The critical metric here is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **no records at all** at the time of evaluation — not that records were examined and none matched the unused-token criteria. This is a fundamental distinction: zero records examined is a **coverage gap finding**, not a threat finding.

No JWT tokens were confirmed as issued-but-unused by this detector run. No malicious activity is evidenced by the event payload. Escalating this to a higher severity based on hypothetical attack paths (e.g., token harvesting, credential stuffing) would be inappropriate given the absence of any supporting evidence in the supplied context.

**What is confirmed by the evidence:**

| Evidence Item | Status |
|---|---|
| Detector invoked successfully by EventBridge Scheduler | ✅ Confirmed |
| DynamoDB table `token-tracking` returned zero records to examine | ✅ Confirmed |
| No unused tokens detected | ✅ Confirmed (within scope of what was registered) |
| All Cognito-issued tokens are

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
