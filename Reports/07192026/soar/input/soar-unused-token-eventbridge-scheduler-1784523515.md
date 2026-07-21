# SOAR Report - unused-token-eventbridge-scheduler-1784523515 - 2026-07-20_04-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:58:35Z
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

The detector fired as scheduled and completed without error. The confirmed evidence is:

| Evidence Item | Status |
|---|---|
| Successful authentication | Confirmed (stated in event) |
| JWT token issued | Confirmed (stated in event) |
| Token unused within 15-minute threshold | Confirmed (stated in event) |
| Token registered in `token-tracking` DynamoDB table | **Not confirmed — zero records examined** |
| Detector malfunction or crash | Not confirmed — detector completed normally |
| Active attack or session hijacking | Hypothetical — no supporting evidence |

The critical finding is not the unused token itself — it is the **gap between what the detector was designed to observe and what it actually observed**. `records_examined: 0` means the DynamoDB table `token-tracking` contained no records at query time. This is a **process-integrity defect**, not a confirmed security incident.

Escalating this to a higher severity based on hypothetical attack paths (credential theft, token harvesting, ghost authentication) would be inappropriate given zero matched records and no corroborating signals. The unused token behavior that triggered

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
