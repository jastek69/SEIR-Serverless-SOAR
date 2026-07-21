# SOAR Report - unused-token-eventbridge-scheduler-1784530115 - 2026-07-20_06-48-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T06:48:35Z
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

**Assessed Severity: INFORMATIONAL (with a conditional escalation path to LOW)**

### Justification

The event contains **no confirmed threat indicators**. Every quantitative field in the detector output is zero: `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0`. There are no findings samples, no flagged tokens, and no evidence of malicious activity within the supplied context.

The severity ceiling is therefore **Informational** under standard tiering frameworks (e.g., NIST SP 800-61, SANS Incident Handling). Elevating severity based solely on the theoretical risk of unused tokens — without a single matched record — would violate the principle of evidence-based triage and create alert fatigue.

**The conditional escalation path to LOW** exists not because of a confirmed threat, but because `records_examined: 0` is itself an anomalous operational signal. A scheduled detector that examines zero records when the system is expected to have active authentication sessions warrants a secondary investigation into whether the detector is functioning correctly. This is an **implementation health concern**, not a security incident.

**Key distinctions applied in this assessment:**

| Signal | Classification | Severity Contribution |

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
