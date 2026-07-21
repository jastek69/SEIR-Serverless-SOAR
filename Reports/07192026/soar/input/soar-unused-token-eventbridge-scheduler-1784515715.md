# SOAR Report - unused-token-eventbridge-scheduler-1784515715 - 2026-07-20_02-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T02:48:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric is `records_examined: 0`, which means the DynamoDB table `token-tracking` contained **zero records eligible for evaluation** at the time of invocation — not that eligible records were examined and none matched. This is a confirmed implementation and operational coverage gap, not evidence of a malicious event.

| Evidence Item | Status | Confidence |
|---|---|---|
| Detector invoked successfully | Confirmed | High |
| DynamoDB table queried | Confirmed | High |
| Zero records in scope for evaluation | Confirmed | High |
| Malicious token misuse | Not evidenced | N/A |
| Attacker-issued or stolen JWT in use | Hypothetical only | N/A |
| Detector logic failure or crash | Not confirmed | Low |

**Key distinction:** The event describes a coverage gap — tokens issued outside the explicit `--track-token` registration path are invisible to this detector. The absence of findings is not exculpatory for those untracked tokens; it simply means the detector has no visibility

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
