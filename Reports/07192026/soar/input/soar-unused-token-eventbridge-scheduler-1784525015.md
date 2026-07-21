# SOAR Report - unused-token-eventbridge-scheduler-1784525015 - 2026-07-20_05-23-35_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-07-20T05:23:35Z
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

**Assessed Severity: INFORMATIONAL / LOW**
**Status: No confirmed threat. Pipeline health gap identified.**

### Justification

The security event contains **zero confirmed threat indicators**. The detector fired as scheduled, examined zero records, matched zero records, and generated zero alerts. There is no evidence of malicious authentication, token theft, credential abuse, or unauthorized access within this event context.

The narrative framing in the prompt ("User authenticated successfully → JWT token issued → Token never used within 15 minutes") describes the **class of threat** this detector is designed to surface — it does not describe a confirmed occurrence within this invocation. The JSON findings confirm this: `records_examined: 0`, `matched: 0`, `alerted: 0`, `findings_total: 0`.

**The only confirmed finding is an operational one:** the detector ran successfully but had no records to evaluate. This is either expected behavior (no tokens were registered for tracking during the window) or it indicates a **coverage gap** in token registration — meaning real Cognito authentications may be occurring outside the tracking pipeline and are therefore invisible to this detector.

Elevating severity based on the hypothetical attack path (ghost authentication, token harvesting, session pre-positioning) would be inappropriate given the absence

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
