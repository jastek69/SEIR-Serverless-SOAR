# SOAR Report - unused-token-eventbridge-scheduler-1784516915 - 2026-07-20_03-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:08:35Z
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

The detector fired as scheduled via EventBridge Scheduler and completed its run without error. The critical metric here is `records_examined: 0`. This means the DynamoDB table `token-tracking` contained **zero records** at the time of evaluation — not zero *matching* records, but zero records examined at all. No token was found to be unused because no token was registered for tracking in the first place.

**Confirmed Evidence:**
- The detector ran successfully and was triggered by the expected source (`eventbridge-scheduler`).
- Zero records were examined, zero were matched, zero alerts were raised.
- The threshold was correctly configured at 15 minutes.
- No anomalous authentication event, no token misuse, and no attacker-controlled artifact is present in the supplied evidence.

**Why severity is not elevated:**

Per the analysis requirement, severity must not be inflated based on hypothetical attack paths when no findings exist. The scenario described in the prompt preamble — "User authenticated successfully, JWT token issued, token never used within 15 minutes" — describes the *intended detection goal* of this detector, not a confirmed observation. The detector

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
