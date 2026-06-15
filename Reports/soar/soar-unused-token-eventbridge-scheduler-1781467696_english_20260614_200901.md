# SOAR Report - unused-token-eventbridge-scheduler-1781467696 - 2026-06-14_20-08-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T20:08:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This is itself a significant secondary signal that warrants investigation alongside the primary behavioral event described. The analysis will address both layers — the described authentication pattern and the detector's apparent failure to capture it.

---

## 1. Severity Assessment

### Rating: **MEDIUM (3.5 / 5)** — with escalation potential to HIGH pending investigation

| Dimension | Assessment |
|---|---|
| Confidentiality Impact | Medium — token may have been exfiltrated |
| Integrity Impact | Low-Medium — no confirmed misuse yet |
| Availability Impact | Low |
| Likelihood of Malicious Activity | Low-Medium (15–30% prior probability) |
| Detection Confidence | **Low** — detector returned 0 scanned records despite described event |

### Justification

The core behavioral signal — a successful authentication followed by a JWT that is never used within the observation window — is **anomalous but not inherently malicious**. However, the risk profile is elevated by several compounding factors:

**Factor 1 — Token as a Persistent Credential**
JWT tokens, particularly those with long expiry windows (common defaults: 1 hour, 24 hours, or longer), represent a portable, signed credential that can be used from *any network location* without re-authentication. An unused token is not a neutralized token. It remains valid until expiry or explicit revocation. If the token was issued and immediately exfiltrated — via a compromised client, a man-in-the-browser attack, or a malicious browser extension — the attacker now holds a valid credential with no further interaction required on the victim's system.

**Factor 2 — The Detector Blind Spot**
The JSON context shows `"scanned": 0` and `"findings_total": 0`. If the described event (auth + unused token) genuinely occurred, the detector either:
- Failed to ingest the relevant log source
- Has a pipeline gap (EventBridge → Lambda/processor → data store)
- Is operating against a stale or empty dataset
- Has a misconfigured threshold or filter

This means the **detection control itself is unreliable**, which upgrades the severity of any finding in this category because you cannot trust the absence of findings as evidence of absence of threat.

**Factor 3 — Blast Radius**
Depending on the token's scope (claims, roles, permissions), a stolen JWT could grant access to APIs, microservices, data stores, or administrative functions. Without knowing the token's `sub`, `aud`, `scope`, or `roles` claims, the blast radius is undefined — which is itself a risk.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Benign User Behavior (Probability: ~45%)
**Description:** The user authenticated (e.g., clicked a login link, triggered SSO), received a token, but then closed the browser tab, was interrupted, lost connectivity, or navigated away before performing any action.

**Supporting indicators:**
- Single authentication event with no subsequent API calls
- No geographic or device anomalies on the auth event
- Occurs during business hours for the user's timezone
- User has a history of similar short sessions

**Why it still matters:** Even benign unused tokens represent an attack surface. If the user's session was abandoned on a shared or public device, the token may be accessible in browser storage.

---

### Rank 2 — Automated Script or Bot Authentication Failure (Probability: ~20%)
**Description:** A service account, CI/CD pipeline, or automated process authenticated successfully but then failed to proceed — due to a misconfiguration, network error, or application bug — leaving the token unused.

**Supporting indicators:**
- Authentication occurred outside business hours
- The authenticating user agent is non-browser (e.g., `python-requests`, `curl`, custom SDK)
- The source IP belongs to a known internal automation subnet or cloud provider CIDR
- The account is a service account rather than a human identity

**Risk implication:** Service account tokens often carry elevated privileges. A broken automation pipeline that repeatedly authenticates without consuming the token may be generating a pool of valid, unused, high-privilege tokens — each representing an attack opportunity.

---

### Rank 3 — Credential Stuffing / Account Takeover Probe (Probability: ~15%)
**Description:** An attacker used valid credentials (obtained via breach, phishing, or credential stuffing) to authenticate and harvest a JWT. The token was not used *from the observed environment* because the attacker intends to use it from a different location, or is staging for a later attack.

**Supporting indicators:**
- Authentication source IP is a VPN exit node, Tor exit node, or datacenter IP not associated with the user
- Authentication occurred at an unusual time for the user
- The user's credentials recently appeared in a breach dataset (check HaveIBeenPwned, internal threat intel)
- Multiple failed authentications preceded the successful one (credential stuffing pattern)
- User-Agent string is generic or inconsistent with the user's known devices

**Attack path detail:**
```
Attacker obtains credentials (breach/phishing)
        ↓
Authenticates via legitimate login endpoint
        ↓
JWT issued and captured (via proxy, malicious extension, or direct API call)
        ↓
Token exfiltrated to attacker infrastructure
        ↓
[Silence — no activity from victim's IP]
        ↓
Token used later from attacker-controlled IP
        ↓
Lateral movement / data exfiltration / privilege escalation
```

This is particularly dangerous because the gap between token issuance and token use can span hours or days, making correlation difficult without robust token-level telemetry.

---

### Rank 4 — Token Exfiltration via Client-Side Attack (Probability: ~10%)
**Description:** The user legitimately authenticated, but a client-side attack (XSS, malicious browser extension, compromised JavaScript dependency) intercepted and exfiltrated the JWT before the user could use it.

**Supporting indicators:**
- The application stores JWTs in `localStorage` or `sessionStorage` (accessible to JavaScript)
- Recent changes to front-end dependencies (supply chain risk)
- CSP (Content Security Policy) violations logged around the same time
- The user reports the application "didn't work" after login

**Why this is insidious:** The legitimate user may have experienced a normal-looking login flow. The token theft is invisible to server-side logging. The only observable artifact is exactly what was described: auth success, token issued, token never used from the expected client.

---

### Rank 5 — Detector / Pipeline Malfunction (Probability: ~8%)
**Description:** The event described may not have occurred as stated, or the detector is generating phantom alerts based on misconfigured logic. The `"scanned": 0` in the JSON strongly supports this as a contributing factor.

**Supporting indicators:**
- `"scanned": 0` — no records were actually evaluated
- `"findings_total": 0` — consistent with no data being processed
- The trigger fired (EventBridge Scheduler ran) but the downstream processor found nothing to analyze
- Possible causes: empty data source, IAM permission error preventing data read, Lambda cold start timeout, incorrect time window query

---

### Rank 6 — Insider Threat / Deliberate Token Harvesting (Probability: ~2%)
**Description:** A malicious insider or compromised privileged user is deliberately authenticating to generate tokens for later use or to share credentials with an external party.

**Supporting indicators:**
- The authenticating account belongs
