# SOAR Report - unused-token-eventbridge-scheduler-1781382242 - 2026-06-13_20-24-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:24:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This is itself a significant signal — the security event description (user authenticated, token issued, token unused within 15 minutes) may represent a *hypothetical trigger condition* or a **detector malfunction/misconfiguration** rather than a confirmed live incident. Both dimensions are analyzed below.

---

## 1. Severity Assessment

### Primary Event (Unused Token Pattern): **LOW–MEDIUM**
### Secondary Event (Detector Anomaly — 0 scanned, 0 alerted): **MEDIUM–HIGH**

---

### Justification

| Dimension | Assessment | Rationale |
|---|---|---|
| Confidentiality Impact | Low–Medium | Token exists but shows no evidence of use; potential credential harvesting without exploitation |
| Integrity Impact | Low | No resource modification observed |
| Availability Impact | None | No service disruption indicators |
| Likelihood of Malicious Activity | Low–Medium | Majority of unused token events are benign; minority represent recon or automation probing |
| Detector Health Risk | **High** | `scanned: 0` on a scheduled detector is a critical gap — blind spots in token monitoring create undetected lateral movement opportunities |

### Severity Escalation Triggers
The severity should be **immediately escalated to HIGH** if any of the following are confirmed:
- The authenticating user account is privileged (admin, service account, IAM role)
- The source IP is from a Tor exit node, VPN provider, or unfamiliar geography
- Multiple accounts show the same pattern within the same time window (credential stuffing indicator)
- The `scanned: 0` condition persists across multiple scheduler invocations (systematic blind spot)

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Benign User Behavior (Probability: ~55%)
**Description:** The user authenticated but abandoned the session before performing any action. Common causes include:
- Browser tab closed immediately after login
- Session timeout on a slow network before the user could interact
- User authenticated to check something, found the answer elsewhere, and closed the tab
- Mobile app backgrounded by the OS before token use

**Evidence alignment:** Single event, no correlated anomalies, no lateral movement, no resource access attempts.

**Risk:** Minimal. Standard user behavior pattern.

---

### Rank 2 — Automated Script or Bot Authentication Probe (Probability: ~20%)
**Description:** An automated process authenticated to validate credentials or test endpoint availability without needing to consume the token. This is characteristic of:
- **Credential validation bots** used in credential stuffing attacks — authenticate to confirm validity, store credentials for later use, never use the token in the current session
- **Synthetic monitoring tools** that test login flows but don't exercise downstream APIs
- **CI/CD pipeline misconfiguration** where auth succeeds but the subsequent API call step fails silently

**Attack Path:**
```
Attacker harvests credential list (breach database)
    → Automated bot authenticates against target
    → Successful auth = credential confirmed valid
    → Token discarded (not needed yet)
    → Credential stored for targeted attack later
    → Days/weeks later: full account takeover
```

**Blast Radius:** If this is credential stuffing, the blast radius extends to all accounts in the harvested list. The unused token is a *low-noise confirmation step* — the real damage comes later.

**Detection Gap:** Traditional brute-force detection (failed login thresholds) completely misses this pattern because **the authentication succeeds**. This is precisely why unused token detection exists — but only if `scanned > 0`.

---

### Rank 3 — Token Harvesting / Man-in-the-Middle Interception (Probability: ~10%)
**Description:** An adversary intercepted the JWT token in transit (or via XSS, log injection, or insecure storage) and is holding it for later use. The legitimate user authenticated normally but the token was silently exfiltrated.

**Attack Path:**
```
Legitimate user authenticates → JWT issued
    → Adversary intercepts token (XSS / network intercept / log exposure)
    → Legitimate user session ends (token "unused" from app perspective)
    → Adversary uses token later from different IP/device
    → Token still valid if long-lived
```

**Key Risk Factor:** JWT tokens with long expiry windows (>15 minutes) remain exploitable well after the "unused" detection window closes. If the token TTL is 1 hour or 24 hours, the adversary has a wide exploitation window.

**Detection Gap:** The unused token detector catches the *absence* of use, but won't catch *delayed* use after the threshold window. Post-threshold token use from a different IP/device fingerprint requires a separate behavioral detection rule.

---

### Rank 4 — Application or Integration Error (Probability: ~10%)
**Description:** A backend service, microservice, or third-party integration authenticated programmatically but failed to use the token due to:
- Application exception after auth but before API call
- Race condition in token handoff between services
- Misconfigured service account with incorrect downstream endpoint

**Risk:** Low from a security perspective, but indicates a reliability/observability gap. Service accounts that authenticate and fail silently can mask both security events and operational failures.

---

### Rank 5 — Reconnaissance / Account Enumeration (Probability: ~5%)
**Description:** An adversary is mapping valid accounts by authenticating with known or guessed credentials. Successful auth confirms account existence and credential validity without triggering resource-access alerts.

**Distinguishing Indicators:**
- Multiple accounts showing the same pattern in a short window
- Authentication from shared infrastructure (same ASN, same IP range)
- Accounts that don't normally authenticate from that geography or device type

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Investigate the detector anomaly FIRST
```

- [ ] **Verify why `scanned: 0`** — Query the token store/database directly to confirm whether tokens exist in the relevant time window. If tokens exist but weren't scanned, the detector is broken.
- [ ] **Check EventBridge Scheduler execution logs** — Confirm the Lambda/function invoked by the scheduler executed successfully. Look for timeout errors, permission denials, or cold-start failures.
- [ ] **Validate IAM permissions** — Confirm the detector's execution role has read access to the token store (DynamoDB, Redis, RDS — wherever JWTs are tracked).
- [ ] **Cross-reference auth logs independently** — Query CloudTrail, your IdP logs (Okta, Cognito, Auth0), or application logs directly for authentication events in the past 15–60 minutes, bypassing the detector entirely.

### Short-Term Actions (1–24 Hours)

- [ ] **Profile the authenticating user/account:**
  - Is this a human user or service account?
  - What is their normal authentication pattern (time of day, geography, device)?
  - Have they authenticated without subsequent activity before?
  - Are they a privileged user?

- [ ] **Analyze the source IP:**
  - Geolocate and compare against user's historical login locations
  - Check against threat intelligence feeds (VirusTotal, Shodan, AbuseIPDB)
  - Identify if IP belongs to known VPN/proxy/Tor infrastructure
  - Check for other accounts authenticating from the same IP in the same window

- [ ] **Review token configuration:**
  - What is
