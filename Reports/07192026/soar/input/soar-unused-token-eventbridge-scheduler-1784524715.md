# SOAR Report - unused-token-eventbridge-scheduler-1784524715 - 2026-07-20_05-18-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:18:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (Operational Gap — Not an Active Security Incident)**

**Justification:**

The detector fired as scheduled and completed without error. The critical finding is not a confirmed attack or compromise — it is that `records_examined: 0`, meaning the DynamoDB table `token-tracking` contained **no records at the time of evaluation**. This is an **operational and coverage gap**, not confirmed malicious activity.

The distinction matters:

| Dimension | Assessment |
|---|---|
| Confirmed threat indicators | None |
| Confirmed authentication anomaly | None — no token records were present to evaluate |
| Confirmed system failure | Not confirmed — detector ran successfully |
| Coverage gap | **Confirmed** — no tokens were registered for tracking |
| Risk elevation from hypothetical paths | Not applied per analytical discipline |

The severity would escalate to **MEDIUM or HIGH** only if investigation confirms that Cognito tokens *are* being issued in production and *should* be registered but are not — indicating a registration pipeline failure. Until that is confirmed, this remains informational.

**Blast Radius (if coverage gap is real):**
If the token-tracking registration step is silently failing or was never wired

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
