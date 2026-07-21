# SOAR Report - unused-token-eventbridge-scheduler-1784507915 - 2026-07-20_00-38-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:38:35Z
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

**Severity: INFORMATIONAL (with operational flag for investigation)**

**Justification:**

The detector fired as scheduled and completed without error. All quantitative findings are zero: `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0`. There is **no confirmed evidence of a malicious unused token, a credential abuse event, or an authentication anomaly** in this execution cycle.

The severity is held at **Informational** rather than elevated for the following reasons grounded strictly in the supplied evidence:

| Factor | Evidence | Implication |
|---|---|---|
| Detector executed successfully | `trigger_source: eventbridge-scheduler`, `reason` field populated | Pipeline is alive; no execution failure |
| Zero records examined | `records_examined: 0` | DynamoDB table `token-tracking` returned no rows to the detector in this run |
| Zero matches, zero alerts | `matched: 0`, `alerted: 0` | No threshold breach detected |
| Token registration is opt-in | `cognito_jwt_linkage` fact | Tokens from Cognito clients that did not use `--track-token` are architecturally invisible to this detector

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
