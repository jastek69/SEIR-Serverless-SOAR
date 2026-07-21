# SOAR Report - unused-token-eventbridge-scheduler-1784522615 - 2026-07-20_04-43-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:43:35Z
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

**Severity: INFORMATIONAL (with a process-integrity flag warranting follow-up)**

### Justification

The event contains **zero confirmed threat indicators**. No authentication anomalies, no token abuse, no lateral movement, and no data exfiltration signals are present in the supplied evidence. The detector fired on schedule, completed its scan, and returned zero findings — which is a valid operational outcome.

However, the field `records_examined: 0` is the critical data point requiring scrutiny. A detector that examines zero records cannot confirm the absence of threats; it can only confirm that its input set was empty. This distinction is operationally significant:

| Evidence State | Interpretation |
|---|---|
| `records_examined: 0`, `matched: 0` | No records were available to scan — not the same as "no threats found" |
| `findings_total: 0` | Correct output given zero input; not independently reassuring |
| `alerted: 0` | Expected when input is zero |

**The severity remains INFORMATIONAL** because there is no confirmed attack, no confirmed misconfiguration producing exploitable exposure, and no evidence of token misuse. The zero-record state is a **process-integrity concern**

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
