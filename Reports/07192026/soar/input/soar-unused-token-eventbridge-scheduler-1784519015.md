# SOAR Report - unused-token-eventbridge-scheduler-1784519015 - 2026-07-20_03-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:43:35Z
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

The event contains **zero confirmed security findings**. Every quantitative indicator in the payload — `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0` — is consistent with a detector that ran successfully but found no qualifying records to evaluate. There is no evidence of:

- A compromised credential
- An active session hijacking attempt
- A token replay or theft scenario
- Any anomalous authentication pattern

The trigger fired correctly via EventBridge Scheduler, the detector executed, and it returned a clean result set. Assigning a higher severity based on the *theoretical* risk of unused tokens — when no such tokens were actually detected — would violate the principle of evidence-based severity classification and introduce alert fatigue.

**The conditional escalation path to LOW exists for one reason only:** `records_examined: 0` means the detector found no records in the DynamoDB `token-tracking` table to evaluate. This is architecturally expected if no tokens have been explicitly registered via `mfa_bootstrap.py --track-token`, but it also means the detector cannot confirm the absence of *unregistered*

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
