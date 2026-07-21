# SOAR Report - unused-token-eventbridge-scheduler-1781465896 - 2026-06-14_19-38-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:38:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This is itself a significant secondary signal that warrants investigation alongside the primary behavioral event described. The analysis will address both layers — the described authentication pattern and the detector health anomaly.

---

## 1. Severity Assessment

### Primary Event (Unused Token Post-Authentication)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟡 **LOW–MEDIUM** | Standalone, this pattern is weak signal. Elevated by detector anomaly. |
| **Confidentiality Impact** | Low–Medium | Token exists and is valid; if intercepted, access is possible |
| **Integrity Impact** | Low | No action taken with token |
| **Availability Impact** | Negligible | No system disruption observed |
| **Detection Confidence** | ⚠️ Low | Detector itself shows signs of malfunction |

### Secondary Event (Detector Anomaly — `scanned: 0`)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🔴 **MEDIUM–HIGH** | A detector that scans nothing creates a blind spot across all token activity |
| **Detection Gap Risk** | High | If the detector is broken, unknown numbers of unused tokens may exist undetected |
| **Blast Radius** | Broad | Affects visibility across the entire authentication surface |

### Combined Severity Justification

The authentication event alone (successful login, token issued, token unused for 15 minutes) sits at **LOW** severity in isolation — it has multiple benign explanations. However, the detector reporting `scanned: 0` while being triggered by a scheduler is a **critical operational integrity failure**. A working detector that found nothing is reassuring. A detector that scanned nothing is a liability. The combined picture elevates the overall posture concern to **MEDIUM**, with the detector issue independently warranting **HIGH** priority remediation.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Primary Event (Token Issued, Never Used)

---

#### 🥇 Rank 1 — Benign User Abandonment (Likelihood: ~45%)

**Description:** The user authenticated (e.g., clicked a login link, initiated SSO) but abandoned the session before completing any action. Common causes include:

- User was interrupted after login
- Login was triggered by a bookmark or automated redirect the user didn't intend to complete
- Multi-tab browsing where the user switched context
- Mobile app backgrounded immediately after auth

**Evidence alignment:** No anomalous IP, no failed attempts preceding success, no lateral movement indicators. This is the statistical majority case in most enterprise environments.

**Risk:** Negligible if the token expires on schedule and is not intercepted.

---

#### 🥈 Rank 2 — Automated/Scripted Authentication Probe (Likelihood: ~20%)

**Description:** An attacker or automated tool successfully authenticated (via credential stuffing, phishing-harvested credentials, or API key exposure) to validate that credentials are live, without proceeding to exploitation — a technique known as **"low-and-slow" credential validation**.

**Attack path:**
```
Attacker obtains credential list
        ↓
Authenticates against target (success)
        ↓
Token issued — attacker records valid session
        ↓
Does NOT use token immediately (avoids behavioral detection)
        ↓
Token stored for later use or sold
        ↓
[Gap in detection window]
        ↓
Token used days/weeks later from different infrastructure
```

**Why this matters:** Many detection systems look for *token use* anomalies (unusual IP, unusual time). A token that is validated but never used in the initial window evades those controls entirely. The attacker may return later from a clean IP.

**Risk:** HIGH if this is the actual scenario. The token remains valid and represents an open door.

---

#### 🥉 Rank 3 — Client-Side Application Error (Likelihood: ~18%)

**Description:** The authentication succeeded server-side, but the client application failed to store or transmit the token correctly. Examples:

- JavaScript error preventing token storage in `localStorage`/`sessionStorage`/cookie
- Mobile app crash after receiving token
- Network interruption between token receipt and first API call
- CORS misconfiguration blocking subsequent requests
- Token stored in memory lost on page refresh

**Evidence alignment:** This would explain the unused token without any security concern. Should be correlated with client error logs.

**Risk:** Negligible from a security perspective; indicates a UX/reliability bug.

---

#### Rank 4 — Credential Sharing / Delegated Authentication (Likelihood: ~10%)

**Description:** A user authenticated on behalf of another person or system (e.g., IT admin testing an account, shared credentials in a team, service account used by a human). The authenticating party obtained the token but the intended consumer never received or used it.

**Risk:** Low-medium. Credential sharing itself is a policy violation and creates audit trail gaps.

---

#### Rank 5 — Token Interception (Man-in-the-Middle) (Likelihood: ~5%)

**Description:** The token was issued and intercepted in transit (e.g., via TLS stripping, compromised proxy, or rogue Wi-Fi). The legitimate user never received it; the attacker holds it but hasn't used it yet.

**Attack path:**
```
User initiates authentication on compromised network
        ↓
Auth server issues JWT
        ↓
Token intercepted by attacker (TLS downgrade / proxy)
        ↓
Legitimate user receives no token (or receives error)
        ↓
Attacker holds valid JWT
        ↓
Token unused in detection window
```

**Risk:** HIGH if confirmed. Requires network-layer investigation.

---

#### Rank 6 — Reconnaissance / Red Team Activity (Likelihood: ~2%)

**Description:** Internal red team, penetration tester, or external attacker performing reconnaissance authenticated to enumerate what access the token would grant without triggering resource-access alerts.

**Risk:** Medium. Indicates active adversarial interest in the environment.

---

### For the Secondary Event (Detector `scanned: 0`)

| Explanation | Likelihood |
|---|---|
| Bug in detector query/filter returning empty result set | 45% |
| Data source (token store/DB) unavailable at scan time | 25% |
| Permissions/IAM issue preventing detector from reading token records | 15% |
| Token store was genuinely empty (new environment, post-purge) | 10% |
| Deliberate tampering with detector to suppress findings | 5% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### Step 1: Validate the Detector — Priority Zero

Before trusting any finding or absence of findings, the detector must be confirmed operational.

```
□ Check EventBridge Scheduler execution logs — did the Lambda/function actually run?
□ Review CloudWatch Logs for the unused_token_detector function
□ Confirm the token data source (DynamoDB/Redis/RDS) was accessible at execution time
□ Manually query the token store for tokens issued in the last 60 minutes
□ Compare manual query results against detector output
□ Check IAM role permissions for the detector function
□ Verify the detector's query logic hasn't been recently modified
```

**If the detector is confirmed broken:** Escalate immediately. Every token issued
