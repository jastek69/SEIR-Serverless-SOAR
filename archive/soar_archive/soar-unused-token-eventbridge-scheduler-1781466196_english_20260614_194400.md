# SOAR Report - unused-token-eventbridge-scheduler-1781466196 - 2026-06-14_19-43-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:43:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the provided JSON context.** The JSON shows:

- `scanned: 0` — No tokens were actually scanned
- `alerted: 0` — No alerts were generated
- `findings_total: 0` — No findings exist
- `findings_sample: []` — Empty findings array
- `threshold_minutes: 5` — The detector threshold is 5 minutes, not 15

This discrepancy is itself a **security-relevant finding**. The analysis below addresses both the **theoretical event described in the narrative** and the **operational anomaly revealed by the JSON context**, as both warrant investigation.

---

## 1. Severity Assessment

### Narrative Event (Unused Token): `LOW–MEDIUM`
### JSON Detector Anomaly (Zero Scans): `MEDIUM–HIGH`

---

### 1a. Narrative Event Severity — LOW to MEDIUM

| Factor | Assessment |
|---|---|
| Confidentiality Impact | Low — no data access confirmed |
| Integrity Impact | Low — no modifications observed |
| Availability Impact | None |
| Likelihood of Malicious Activity | Low in isolation; elevated in pattern |
| Detection Confidence | Low — absence of use is weak signal |

**Justification:**

An authenticated session where the issued JWT is never used is a weak signal in isolation. A single occurrence is statistically unremarkable — users abandon sessions, close browser tabs, experience connectivity issues, or trigger authentication flows programmatically without completing the intended action. However, the signal strengthens considerably when:

- The pattern repeats across multiple accounts
- The authentication originates from unusual geolocations or ASNs
- The authentication method differs from the user's baseline (e.g., password auth where MFA is normally used)
- The token was issued to a service account or non-human identity
- The authentication occurs outside business hours

The **blast radius** of an unused token is theoretically bounded — if the token was never used, no downstream resources were accessed. However, the act of successful authentication itself confirms valid credentials exist and were exercised, which is meaningful for credential compromise scenarios.

---

### 1b. JSON Detector Anomaly Severity — MEDIUM to HIGH

**This is the more operationally significant finding.** A detector that scanned zero records when it should be scanning active JWT sessions indicates one of the following:

- The detection pipeline is broken or misconfigured
- There are genuinely no active sessions in the token store (unexpected in production)
- The EventBridge Scheduler triggered the Lambda/function prematurely before token data was available
- The token store query is failing silently
- A **detection gap** exists — the system believes it is monitoring when it is not

A non-functional detector is a **force multiplier for attackers**. If unused tokens (a potential indicator of credential stuffing, account enumeration, or automated reconnaissance) are not being detected, the entire control is providing false assurance.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Narrative Event (Unused Token)

---

**Rank 1 — Benign User Abandonment (Probability: ~60%)**

The most common explanation. The user initiated a login flow and abandoned it before completing their intended action. Common causes:

- Browser tab closed or navigated away
- Session initiated by a "remember me" or SSO pre-fetch mechanism
- Mobile app backgrounded before completing the flow
- User distracted or interrupted
- Slow network caused the user to give up

*Risk:* Minimal. The token expires naturally. No action required unless pattern repeats.

---

**Rank 2 — Automated/Scripted Authentication Probe (Probability: ~20%)**

An automated system authenticated successfully but the downstream workflow failed, was interrupted, or was designed only to validate credentials without proceeding. This is common in:

- Credential stuffing tools that validate credentials and log results without proceeding to account takeover immediately
- Reconnaissance scripts that confirm account existence
- Broken CI/CD pipelines that authenticate to APIs but fail before making requests
- Monitoring agents that perform synthetic login checks

*Risk:* Medium-High if malicious. Successful credential validation confirms the account is compromised. The attacker may return later to use the credentials, avoiding the "unused token" detection window by spacing their activity.

**Attack path:**
```
Attacker obtains credential list → Validates credentials via auth endpoint
→ Logs valid accounts → Returns later with fresh authentication
→ Bypasses unused-token detector by using token immediately on second attempt
```

---

**Rank 3 — Token Issuance to Non-Human Identity / Service Account (Probability: ~10%)**

A service account or machine identity authenticated but the downstream service that would consume the token failed to start, crashed, or was misconfigured. The token was issued to a process that never ran.

*Risk:* Low-Medium. Indicates infrastructure misconfiguration. If the service account credentials are exposed, this could indicate unauthorized use.

---

**Rank 4 — Session Pre-Warming / Speculative Authentication (Probability: ~5%)**

Some application architectures pre-authenticate users speculatively (e.g., during page load) before the user explicitly triggers an action. If the user navigates away before the action completes, the token is orphaned.

*Risk:* Low. Architectural concern rather than security incident.

---

**Rank 5 — Insider Threat / Authorized User Reconnaissance (Probability: ~3%)**

An authorized user authenticated to confirm their credentials still work, or to test system availability, without intending to perform their normal workflow. Could indicate:

- An employee preparing to exfiltrate data (confirming access before acting)
- A user testing credentials before sharing them with an unauthorized party

*Risk:* Medium. Difficult to distinguish from benign behavior without behavioral baseline.

---

**Rank 6 — Account Takeover — Attacker Interrupted (Probability: ~2%)**

An attacker used compromised credentials, received a token, but was interrupted before using it (e.g., MFA challenge on downstream resource, unexpected CAPTCHA, network interruption, or defensive control triggered).

*Risk:* High if confirmed. The authentication itself represents a successful breach of the first authentication layer.

---

### For the JSON Detector Anomaly (Zero Scans)

| Rank | Explanation | Probability |
|---|---|---|
| 1 | EventBridge triggered before token store was populated (timing issue) | 40% |
| 2 | Token store query returning empty due to misconfiguration or schema change | 25% |
| 3 | Lambda/detector function has a silent exception swallowing errors | 20% |
| 4 | Token store is genuinely empty (no active sessions — valid in dev/staging) | 10% |
| 5 | Malicious actor cleared token store or manipulated detector output | 5% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

**Action 1: Validate the Detector Pipeline**

The zero-scan result is the highest priority. Before investigating the narrative event, confirm the detection infrastructure is functional.

```
□ Check EventBridge Scheduler execution logs — did the trigger fire at the correct time?
□ Check Lambda/function execution logs for errors, timeouts, or cold-start issues
□ Manually query the token store — are there active tokens present?
□ Verify the token store connection string/credentials used by the detector
□ Check for recent deployments or schema changes to the token store
□ Run the
