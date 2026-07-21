# SOAR Report - unused-token-eventbridge-scheduler-1784523215 - 2026-07-20_04-53-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T04:53:35Z
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

**Severity: INFORMATIONAL (with operational risk flag)**

### Justification

The detector fired as scheduled and completed without error. The confirmed evidence is:

| Evidence Item | Status |
|---|---|
| Authentication event occurred | **Assumed from event description** — not confirmed in detector output |
| JWT token issued | **Assumed from event description** — not confirmed in detector output |
| Token unused within 15 minutes | **Not confirmed** — detector examined zero records |
| Malicious activity detected | **None** |
| Anomalous authentication pattern detected | **None** |

The critical finding here is not a threat actor — it is a **coverage gap in the detection pipeline itself**. `records_examined: 0` means the detector had nothing to evaluate. This does not confirm that no tokens exist; it confirms that **no tokens were registered in the DynamoDB `token-tracking` table at the time of evaluation**. The authentication and JWT issuance described in the event preamble are therefore **outside the detector's current visibility**.

Assigning a threat-level severity based on the hypothetical misuse of an untracked token would be analytically unsound given zero findings. However, the **operational gap** — where real Cogn

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
