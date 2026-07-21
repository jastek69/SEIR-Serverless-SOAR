# SOAR Report - unused-token-eventbridge-scheduler-1784504015 - 2026-07-19_23-33-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-19T23:33:35Z
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

**Severity: INFORMATIONAL (with a conditional escalation path to LOW)**

### Justification

The event contains **zero confirmed security findings**. The detector fired on schedule, examined zero records, matched zero records, and raised zero alerts. No JWT token was observed sitting unused. No authentication anomaly was confirmed. The security event description ("User authenticated successfully, JWT token issued, token never used within 15 minutes") describes the **class of behavior this detector is designed to catch** — it does not describe a confirmed instance of that behavior occurring during this invocation.

The severity is therefore **Informational** based on the evidence supplied. Assigning a higher severity based on the hypothetical scenario described in the event class description — without a matched record to anchor it — would violate sound triage discipline.

**Conditional escalation trigger:** If subsequent invocations continue to return `records_examined: 0` despite known authentication activity in Cognito, the severity should be escalated to **LOW** and the detector's registration pipeline should be treated as a potential detection gap, not a clean bill of health.

---

## 2. Possible Explanations Ranked by Likelihood

The following explanations address why `records_examined` is zero. They are ranked from most to least

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
