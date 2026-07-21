# SOAR Report - unused-token-eventbridge-scheduler-1784519915 - 2026-07-20_03-58-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T03:58:35Z
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

**Assessed Severity: INFORMATIONAL (No Active Incident)**

**Justification:**

The detector fired as scheduled, completed its scan, and returned zero records examined, zero matches, and zero alerts. There is no confirmed evidence of a malicious authentication event, a compromised token, or a detection failure at this time.

The critical distinction to establish upfront is between three separate concerns:

| Concern | Status | Basis |
|---|---|---|
| Active security incident (unused token abuse) | **Not confirmed** | No records, no matches, no alerts |
| Detection coverage gap (tokens not registered) | **Confirmed architectural limitation** | `implementation_facts.cognito_jwt_linkage` explicitly states other Cognito clients are not automatically registered |
| Detector operational failure | **Not confirmed** | Zero records examined is consistent with an empty or unpopulated token-tracking table, not a detector crash |

Elevating severity based on the hypothetical "what if a token was issued and not tracked" would be analytically unsound given the evidence. The correct response is to treat this as an **informational finding with a confirmed architectural gap** that warrants remediation planning, not incident escalation.

---

## 2. Possible Explan

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
