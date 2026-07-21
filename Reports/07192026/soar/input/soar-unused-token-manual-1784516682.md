# SOAR Report - unused-token-manual-1784516682 - 2026-07-20_03-04-42_UTC

- Trigger: manual
- Generated: 2026-07-20T03:04:42Z
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

**Severity: INFORMATIONAL**
**Confidence: High**

**Justification:**

The confirmed evidence from this event is narrow and unambiguous: the `unused_token_detector` was triggered manually by an operator, examined **zero records**, matched **zero records**, and generated **zero alerts**. There are no findings, no anomalous authentication events, no confirmed unused tokens, and no indicators of compromise present in the supplied data.

The severity cannot be elevated based on hypothetical attack paths. The absence of records examined is itself the primary finding — it is a **detector coverage gap**, not a security incident. Assigning a higher severity would require confirmed evidence of malicious activity, which does not exist in this event.

**What is confirmed:**
- The detector ran successfully (it produced a structured result with zero counts rather than an error).
- The DynamoDB table `token-tracking` returned zero records to the detector at the time of execution.
- The tracking mechanism is **opt-in by design**: only tokens explicitly registered via `mfa_bootstrap.py --track-token` or synthetic markers are present in the table.
- Cognito-issued JWT tokens from other client flows are **not automatically registered** and therefore are **invisible to this detector**.

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
