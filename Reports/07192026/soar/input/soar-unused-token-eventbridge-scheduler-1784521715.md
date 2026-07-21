# SOAR Report - unused-token-eventbridge-scheduler-1784521715 - 2026-07-20_04-28-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:28:35Z
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

**Assessed Severity: INFORMATIONAL / LOW (with a conditional escalation path to MEDIUM)**

### Justification

The detector fired as scheduled and completed without error. All quantitative findings fields — `records_examined`, `matched`, `alerted`, and `findings_total` — are zero. There are no confirmed malicious indicators, no anomalous authentication artifacts, and no evidence of token misuse in the supplied event context.

**The zero-record result is the central finding and must be interpreted carefully.** It does not confirm that no unused tokens exist in the environment. It confirms only that the detector examined zero records from the `token-tracking` DynamoDB table during this invocation. The distinction is critical:

| Interpretation | Supported by Evidence? |
|---|---|
| No unused tokens exist | ❌ Not confirmed |
| Detector ran and found nothing to examine | ✅ Confirmed |
| Detector failed silently | ❌ Not confirmed, but cannot be ruled out |
| Token registration pipeline has a gap | ⚠️ Plausible — see Section 2 |

The scenario described in the event header — *"User authenticated successfully, JWT token issued, token never used within 15

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
