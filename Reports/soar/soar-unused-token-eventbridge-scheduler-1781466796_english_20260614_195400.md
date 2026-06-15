# SOAR Report - unused-token-eventbridge-scheduler-1781466796 - 2026-06-14_19-53-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:53:16Z
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
# Security Event Analysis: Unused JWT Token After Successful Authentication

---

## Preliminary Note: Context Reconciliation

Before proceeding, a critical observation must be surfaced. **There is a material discrepancy between the narrative event description and the JSON security context provided.**

| Field | Narrative Description | JSON Context |
|---|---|---|
| Authentication | User authenticated, JWT issued | Not referenced |
| Token usage | Token unused within 15 minutes | `threshold_minutes: 5` |
| Findings | Implied suspicious activity | `findings_total: 0`, `scanned: 0` |
| Alert state | Implied alert condition | `alerted: 0` |

**The JSON context represents a detector invocation that found nothing** — zero tokens scanned, zero findings, zero alerts. This is itself a significant signal and will be treated as a **secondary anomaly** alongside the primary behavioral pattern described in the narrative. Both will be analyzed in full.

---

## 1. Severity Assessment

### Primary Behavioral Pattern (Narrative): Unused Token Post-Authentication

> **Severity: MEDIUM (with escalation triggers to HIGH)**

**Justification:**

In isolation, a single unused JWT following successful authentication is a low-fidelity signal. However, the combination of *successful authentication* followed by *complete token non-use* represents a behavioral deviation from expected user patterns that warrants structured investigation. The risk profile escalates significantly when correlated with:

- **Volume**: Multiple accounts exhibiting this pattern simultaneously
- **Account type**: Privileged, service, or administrative accounts
- **Authentication method**: Password-only vs. MFA-protected
- **Source IP reputation**: Known bad actor infrastructure, Tor exit nodes, residential proxies
- **Time of day**: Off-hours authentication with no follow-through

**Blast Radius Consideration:**

If this pattern represents credential testing or token harvesting at scale, the blast radius extends to:
- All resources accessible by the authenticated identity
- Downstream systems trusting the JWT (microservices, APIs, third-party integrations)
- Audit log integrity if the actor is probing detection thresholds
- Compliance posture (SOC 2, ISO 27001, PCI-DSS) if PII or cardholder data is in scope

**Detection Gap Risk:**

The 15-minute (narrative) / 5-minute (JSON threshold) window creates a **detection latency gap**. An attacker who uses a token once within the threshold window and then abandons it would evade this detector entirely. This is a known weakness in threshold-based behavioral detection.

---

### Secondary Anomaly (JSON Context): Detector Invoked With Zero Scanned Records

> **Severity: MEDIUM-HIGH**

**Justification:**

`"scanned": 0` on a scheduled detector invocation is a **silent failure condition**. A detector that runs but examines no records is functionally equivalent to a disabled detector. This represents a **detection coverage gap** that could allow the primary behavioral pattern to go entirely undetected at scale.

Possible causes range from benign (empty token store at scan time, misconfigured query scope) to malicious (log tampering, token store access revoked from detector role, active evasion).

---

## 2. Possible Explanations Ranked by Likelihood

### For the Primary Behavioral Pattern (Unused Token)

---

**Rank 1 — Benign User Abandonment (Likelihood: ~45%)**

The user authenticated, was interrupted, closed the browser tab, lost connectivity, or navigated away before completing their intended action. The token expired naturally. This is the most statistically common explanation in enterprise environments, particularly for:
- Web applications with long or complex login flows
- Mobile applications with poor network handling
- SSO-initiated sessions where the user authenticated but the redirect failed silently

*Supporting indicators:* Single occurrence, daytime hours, known user agent, consistent source IP with historical logins.

---

**Rank 2 — Application or Client-Side Error (Likelihood: ~25%)**

A bug in the client application, browser extension conflict, or misconfigured redirect URI caused the token to be issued but never delivered to or consumed by the application. The user may have experienced a blank screen or error page and abandoned the session.

*Supporting indicators:* Cluster of events tied to a specific application version, user agent, or deployment window. Correlated with application error logs showing 4xx/5xx responses near authentication time.

---

**Rank 3 — Automated Credential Validation / Credential Stuffing (Likelihood: ~15%)**

An adversary using compromised credentials (sourced from breach databases) is validating which credentials are live without triggering downstream detection. The pattern of "authenticate, receive token, discard" is a deliberate evasion technique — the attacker confirms the account is active and the password is valid, then saves the credential for later exploitation or sale.

*Supporting indicators:*
- Source IP is a datacenter, VPN exit node, or known proxy
- Authentication occurred outside business hours
- No prior authentication history from this IP
- Multiple accounts showing the same pattern in a short window
- Velocity anomalies in authentication logs
- User-agent string is generic, headless browser, or curl-like

*Attack path detail:*
```
[Attacker] → Credential Stuffing Tool (e.g., Sentry MBA, OpenBullet)
    → POST /auth/login with breached credentials
    → Receives 200 OK + JWT
    → Logs "credential valid" 
    → Does NOT call any API endpoint (avoids triggering behavioral analytics)
    → Moves to next credential pair
    → Returns later with valid credentials for targeted exploitation
```

---

**Rank 4 — Token Harvesting for Offline Attack or Replay (Likelihood: ~8%)**

The attacker authenticated to obtain a long-lived JWT, extracted it for offline analysis (e.g., to crack the signing secret via brute force if HS256 is used), or is staging it for a replay attack against a service that does not validate token freshness.

*Supporting indicators:*
- JWT algorithm is HS256 with a weak or default secret
- Token expiry (`exp` claim) is unusually long (hours or days)
- No token revocation mechanism exists
- The application does not validate `iat` (issued-at) or `jti` (JWT ID) claims

---

**Rank 5 — Insider Threat / Account Sharing Probe (Likelihood: ~4%)**

A legitimate user authenticated on behalf of another person (account sharing), or an insider is testing whether their credentials still work following a role change, termination notice, or access review — without wanting to leave a usage trail.

*Supporting indicators:*
- Authentication from an unusual device or location for this user
- Recent HR events (termination, role change, PIP) associated with the account
- Authentication during non-working hours for the user's timezone

---

**Rank 6 — Security Research or Penetration Testing (Likelihood: ~3%)**

An authorized or unauthorized security researcher is probing the authentication endpoint. Authorized testing should be documented; undocumented testing is itself a policy violation.

---

### For the Secondary Anomaly (`scanned: 0`)

---

**Rank 1 — Empty Token Store at Scan Time (Likelihood: ~40%)**

If tokens are stored in a cache (Redis, Memcached) with TTL-based expiry, it is possible that all tokens had already expired before the scheduler fired, resulting in a legitimately empty scan set. This is more likely if the threshold is short (5 minutes) and token TTL is also short.

---

**Rank 2 — Misconfigured Query Scope or Filter (Likelihood: ~35%)**

The detector's query is filtering too aggressively — wrong table, wrong time window, incorrect status
