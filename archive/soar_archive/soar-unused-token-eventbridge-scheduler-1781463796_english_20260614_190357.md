# SOAR Report - unused-token-eventbridge-scheduler-1781463796 - 2026-06-14_19-03-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:03:16Z
- Threshold Minutes: 5
- Records Scanned: 0
- Alerts Published: 0
- Reason: Unused token check invoked by EventBridge Scheduler
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Post-Authentication

---

## Preliminary Note on Event Context

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and an empty `findings_sample`. This means the detector ran but found **nothing to analyze** — either because no tokens existed in scope, the data pipeline feeding the detector is broken, or the detection threshold mismatch (narrative says 15 minutes, JSON says `threshold_minutes: 5`) caused a logic gap.

This discrepancy is itself a security finding and is treated as a primary concern throughout this analysis.

---

## 1. Severity Assessment

### Overall Severity: **MEDIUM** (with a nested CRITICAL sub-finding)

| Dimension | Rating | Justification |
|---|---|---|
| Narrative Event (Unused Token) | LOW–MEDIUM | Unused tokens are common but warrant investigation |
| Detector Malfunction / Blind Spot | **CRITICAL** | `scanned: 0` means the control is not functioning — zero visibility |
| Threshold Mismatch | MEDIUM | 15-min narrative vs. 5-min config creates detection gap |
| Blast Radius | HIGH | If detector is broken, all unused-token abuse goes undetected |
| Detection Confidence | VERY LOW | No data was processed; findings cannot be trusted |

### Justification

An unused JWT following successful authentication is a **weak signal in isolation** — users abandon sessions, close browsers, or authenticate programmatically and defer action. However, the **combination** of a non-functioning detector (`scanned: 0`) with an authentication event creates a meaningful blind spot. If an adversary is:

- Harvesting valid tokens for later use
- Testing credential validity without triggering downstream behavioral analytics
- Performing token exfiltration (issuing tokens via compromised automation, storing them externally)

...then a broken unused-token detector is precisely the control gap they would exploit. The **blast radius** extends to every user session in the system during the detector's downtime.

---

## 2. Possible Explanations Ranked by Likelihood

### Track A: Explanations for the Unused Token Behavior

| Rank | Explanation | Likelihood | Notes |
|---|---|---|---|
| 1 | User authenticated and abandoned the session (browser close, distraction, UX friction) | **Very High** | Most common real-world cause |
| 2 | Automated/scripted authentication where the downstream job failed or was delayed | **High** | CI/CD pipelines, cron jobs, service accounts |
| 3 | User authenticated on one device, switched to another (token not transferred) | **Medium** | Common in mobile/desktop split workflows |
| 4 | Token issued for a future-scheduled operation (intentional deferred use) | **Medium** | Batch processing, scheduled tasks |
| 5 | Credential stuffing probe — attacker validates credentials without proceeding | **Medium** | Attacker confirms account is live, stops to avoid detection |
| 6 | Token exfiltration — token issued, exfiltrated, to be used from a different origin | **Low–Medium** | Sophisticated; requires prior foothold |
| 7 | Reconnaissance via authentication oracle — testing which accounts are valid | **Low–Medium** | Often seen in large-scale automated attacks |
| 8 | Insider threat — employee authenticates from unusual context, abandons session | **Low** | Requires corroborating signals |

### Track B: Explanations for `scanned: 0` (Detector Failure)

| Rank | Explanation | Likelihood | Notes |
|---|---|---|---|
| 1 | Token store / data source not connected or returning empty results | **Very High** | Misconfigured data source, empty table, wrong environment |
| 2 | EventBridge Scheduler fired but Lambda/consumer had a cold-start failure or timeout | **High** | No error surfaced if exception is swallowed |
| 3 | IAM permission issue — detector cannot read token store | **High** | Silent failure if exception handling is too broad |
| 4 | Threshold mismatch caused zero tokens to qualify (5 min vs. 15 min) | **Medium** | If tokens expire at 10 min, neither threshold catches them |
| 5 | Detector deployed to wrong environment (dev vs. prod) | **Medium** | EventBridge rule pointing at wrong Lambda ARN |
| 6 | Token store was recently cleared/rotated legitimately | **Low** | Possible but would show `scanned > 0` |
| 7 | Adversarial evasion — tokens used just before detector window | **Low** | Requires knowledge of detector schedule |

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

```
Priority 1: Validate detector health — this is the most urgent finding.
```

- [ ] **Check Lambda execution logs** in CloudWatch for the `unused_token_detector` function. Look for exceptions, timeouts, or empty-result returns.
- [ ] **Verify IAM role permissions** attached to the Lambda — confirm it has `read` access to the token store (DynamoDB, Redis, RDS, etc.).
- [ ] **Manually query the token store** to confirm whether tokens exist that should have been scanned. If tokens exist but `scanned: 0`, the pipeline is broken.
- [ ] **Confirm EventBridge Scheduler target** — validate the ARN, region, and environment tag match production.
- [ ] **Check for threshold logic bug** — review the detector code to confirm whether the `threshold_minutes: 5` is applied as `issued_at < now - 5min` or `issued_at > now - 5min` (off-by-one or inverted logic is common).

### Short-Term (1–24 Hours)

- [ ] **Correlate the authentication event** with user behavior logs: IP geolocation, user-agent, device fingerprint, time-of-day baseline.
- [ ] **Check if the authenticated user has prior unused-token events** — a pattern of authenticate-and-abandon is a stronger signal than a single occurrence.
- [ ] **Review all tokens issued in the last 24 hours** that were never used — manually compensate for the broken detector.
- [ ] **Assess whether the token has since been used** — if it was used after the 15-minute window from an unexpected IP or device, escalate immediately.
- [ ] **Audit EventBridge Scheduler invocation history** — confirm the scheduler has been firing on schedule and that this isn't the first missed execution.

### Medium-Term (24–72 Hours)

- [ ] **Fix and redeploy the detector** with proper error handling, observability, and alerting on `scanned: 0` as an anomaly condition.
- [ ] **Implement detector self-health checks** — if `scanned: 0` and the token store is non-empty, fire a separate alert.
- [ ] **Review token TTL policy** — ensure tokens expire within a window that aligns with the detection threshold.
- [ ] **Conduct a gap analysis** on how long the detector has been returning `scanned: 0` — determine the full blind-spot window.

---

## 4. Executive Summary

A security detector designed to identify unused JWT tokens following successful authentication executed successfully from a scheduling perspective but **processed zero records and generated zero findings**. This is not a clean bill of health — it is a **detector failure**.

The underlying authentication event (user
