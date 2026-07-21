# SOAR Report - unused-token-eventbridge-scheduler-1784531315 - 2026-07-20_07-08-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T07:08:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap)**

**Justification:**

The detector fired as scheduled and completed without error. However, `records_examined: 0` means the detector had **no data to evaluate** — it did not find and dismiss records, it found nothing at all. This is a **confirmed operational gap in token visibility**, not a confirmed attack or compromise.

**Critically, no attack path can be confirmed from this event alone.** The event does not confirm that a JWT was issued and went unused; it confirms that the detector has no registered tokens to check. The scenario described in the prompt ("JWT token issued, token never used within 15 minutes") is the *intended detection target*, but the detector's zero-record result means that scenario — if it occurred — would be **invisible to this control**.

**Risk framing:**

| Dimension | Assessment |
|---|---|
| Confirmed malicious activity | None |
| Confirmed system error | None — detector ran to completion |
| Confirmed detection gap | **Yes** — token registration coverage is incomplete |
| Blast radius if gap is exploited | Medium-High — unregistered tokens could be harvested and replayed without detection |
| Urgency | Medium

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
