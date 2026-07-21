# SOAR Report - unused-token-eventbridge-scheduler-1784507015 - 2026-07-20_00-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T00:23:35Z
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

The event contains **zero confirmed threat indicators**. Every quantitative field in the detector output — `records_examined`, `matched`, `alerted`, `findings_total` — is zero. There are no findings, no samples, and no anomalous authentication artifacts surfaced by the detector run itself.

The scenario described in the prompt preamble ("user authenticated successfully, JWT token issued, token never used within 15 minutes") is the **detection hypothesis** the detector is designed to evaluate, not a confirmed observation from this specific run. The detector ran, examined zero records, and produced zero alerts. Assigning a threat-level severity based on a hypothetical authentication event that the detector itself did not surface would be analytically unsound and would violate the principle of evidence-based severity assignment.

**Why not higher severity?**

- No DynamoDB records were examined, meaning no token-tracking entries existed in the `token-tracking` table at the time of invocation.
- The implementation facts confirm that only tokens explicitly registered via `mfa_bootstrap.py --track-token` are tracked. Cognito tokens issued through other client flows are **not automatically registered**.

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
