# SOAR Report - unused-token-eventbridge-scheduler-1784505515 - 2026-07-19_23-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:58:35Z
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

**Severity: INFORMATIONAL (with a conditional escalation path to LOW)**

### Justification

The detector fired as scheduled and completed without error. Every metric in the event payload — `records_examined`, `matched`, `alerted`, and `findings_total` — is zero. There are no confirmed malicious indicators, no anomalous authentication patterns, and no evidence of token misuse in the supplied data.

**Confirmed evidence:**
- EventBridge Scheduler successfully invoked the `unused_token_detector` Lambda.
- The Lambda executed, examined zero records, and produced zero findings.
- The detector is operationally healthy from an invocation standpoint.

**Implementation defect (confirmed):**
- The DynamoDB table `token-tracking` contained zero records at scan time. This is the direct and sole cause of the zero-examination result. This is not a detector failure — it is a coverage gap in token registration.

**Hypothetical threat (not confirmed, not elevated):**
- A successful authentication followed by an unused JWT *could* indicate credential stuffing, token harvesting, or a reconnaissance pattern. However, no such token is registered in the tracking table, so the detector has no surface area to evaluate. Assigning an elevated severity based

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
