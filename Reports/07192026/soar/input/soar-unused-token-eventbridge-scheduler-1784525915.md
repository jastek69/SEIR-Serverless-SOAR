# SOAR Report - unused-token-eventbridge-scheduler-1784525915 - 2026-07-20_05-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:38:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The core finding is `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0`. There are no confirmed indicators of compromise, no flagged tokens, and no anomalous authentication artifacts surfaced by this invocation.

**Critically, the scenario described in the prompt header — "User authenticated successfully, JWT token issued, Token never used within 15 minutes" — is not confirmed by the event data.** The detector examined zero records. This means either:

- No tokens were registered in the DynamoDB `token-tracking` table at the time of invocation, **or**
- The token in question was never registered with the tracking system in the first place.

The absence of findings is **not evidence of a clean environment**; it is evidence of a **coverage gap in the tracking pipeline**. The severity of that gap depends on how broadly Cognito JWTs are issued versus how many are explicitly registered via `mfa_bootstrap.py --track-token`. That gap is an **implementation defect

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
