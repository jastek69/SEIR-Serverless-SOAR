# SOAR Report - unused-token-manual-1784512567 - 2026-07-20_01-56-07_UTC

- Trigger: manual
- Generated: 2026-07-20T01:56:07Z
- Threshold Minutes: 15
- DynamoDB Records Examined: 0
- Active-Unused Records Matched: 0
- Alerts Published: 0
- Reason: Operator-requested unused token review
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Detector — Zero Records Examined

---

## 1. Severity Assessment

**Assessed Severity: INFORMATIONAL**
**Confidence: High**

### Justification

The detector returned `records_examined: 0`, `matched: 0`, `alerted: 0`, and `findings_total: 0`. There are **no confirmed security findings** in this event. The trigger was operator-requested (`trigger_source: manual`), not an automated alert fired by anomalous behavior. No JWT token has been confirmed as issued-but-unused by this detector run.

The scenario described in the prompt preamble — "user authenticated successfully, JWT token issued, token never used within 15 minutes" — represents the **intended detection goal** of this detector, not a confirmed observation from this specific run. That scenario is not evidenced in the event JSON.

**The zero-record result is itself the primary finding.** It indicates one or more of the following:

- The DynamoDB `token-tracking` table contains no records eligible for evaluation at the time of this run.
- Tokens were not registered into the tracking table via `mfa_bootstrap.py --track-token`, so there is nothing for the detector to examine.
- A data pipeline or ingestion gap exists upstream of the detector.

**Severity would

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
