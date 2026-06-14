# SOAR Report - unused-token-eventbridge-scheduler-1781383142 - 2026-06-13_20-39-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:39:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This means the security event description (user authenticated, JWT issued, token unused within 15 minutes) represents either a **hypothetical/templated scenario being evaluated**, a **detection pipeline failure**, or a **gap between the event trigger and the data source it was expected to query**. Both dimensions — the described security event *and* the detector anomaly — are analyzed below, as both carry independent security significance.

---

## 1. Severity Assessment

### Described Event (Unused JWT Post-Authentication)

| Attribute | Assessment |
|---|---|
| **Severity** | LOW–MEDIUM (context-dependent) |
| **Confidence** | LOW (insufficient corroborating signals in isolation) |
| **Urgency** | LOW (no active exploitation confirmed) |
| **Potential Impact** | MEDIUM–HIGH (if part of credential harvesting or token farming) |

### Detector Anomaly (Zero Scans, Zero Findings)

| Attribute | Assessment |
|---|---|
| **Severity** | MEDIUM–HIGH |
| **Confidence** | HIGH (the JSON is unambiguous) |
| **Urgency** | HIGH (blind spot in detection coverage) |
| **Potential Impact** | HIGH (systematic evasion or infrastructure failure) |

---

### Justification

**For the unused token event itself:** A single authentication event that produces an unused JWT is not inherently malicious. Human users abandon sessions, close browsers, and experience connectivity issues routinely. However, at scale or in combination with other indicators — off-hours authentication, unusual geolocation, service account principals, or high-frequency token issuance — this pattern becomes a meaningful signal for:

- **Credential stuffing validation** (attacker confirms credential validity without triggering downstream behavioral analytics)
- **Token farming** (pre-positioning tokens for later use, potentially after rotating infrastructure)
- **Automated probing** (bots testing authentication endpoints)
- **Insider reconnaissance** (user authenticating to systems outside their normal workflow)

The 15-minute threshold in the event description versus the **5-minute threshold** in the detector JSON (`threshold_minutes: 5`) also represents a **threshold inconsistency** that could indicate misconfiguration, stale documentation, or a deliberate tuning change not reflected in operational runbooks.

**For the detector anomaly:** `scanned: 0` is the most operationally significant finding in this entire event. A detector that fires but processes no records means one of the following is true — all of which represent security control failures:

- The data source (token store, auth log, SIEM index) is unreachable or empty
- The query logic has a bug producing an empty result set
- The EventBridge schedule fired against a misconfigured Lambda/function target
- An adversary has tampered with the logging pipeline to suppress evidence

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused Token Pattern

**Rank 1 — Benign User Abandonment (Probability: ~55%)**
The user authenticated (possibly via SSO, OAuth flow, or direct login), received a JWT, and then navigated away, closed the tab, experienced a network interruption, or was distracted before completing their intended action. This is the most statistically common explanation in enterprise environments, particularly for web applications with complex multi-step onboarding flows or MFA prompts that add friction after token issuance.

*Supporting indicators:* Business hours timestamp, known user principal, single authentication event, no prior anomalies on the account.

---

**Rank 2 — Automated Health Check or Integration Test (Probability: ~20%)**
CI/CD pipelines, synthetic monitoring tools (Datadog Synthetics, AWS CloudWatch Synthetics, Pingdom), and integration test suites frequently authenticate against production or staging endpoints to validate that the authentication service is operational. These automated actors obtain tokens but may not proceed to make API calls if the health check only validates the auth response code and token structure.

*Supporting indicators:* Service account principal, consistent timing pattern (e.g., every 5 minutes), non-human user agent string, originating IP from known CI/CD infrastructure.

*Risk note:* If this is the explanation, it represents a **security hygiene issue** — production credentials used in automated testing, service accounts with broader scopes than necessary, and tokens being issued and discarded without revocation.

---

**Rank 3 — Credential Validation / Stuffing Probe (Probability: ~12%)**
Adversaries conducting credential stuffing attacks frequently operate in two phases: (1) validate that credentials are correct by completing the authentication flow and confirming a token is issued, then (2) use those credentials later from different infrastructure to avoid behavioral correlation. The gap between authentication and token use is intentional — it defeats session-based anomaly detection that looks for unusual *activity* rather than unusual *authentication*.

*Attack path detail:*
```
Phase 1 (Validation):
  Attacker IP A → POST /auth/login → 200 OK + JWT issued
  [Token never used — validation confirmed, credentials marked "valid"]

Phase 2 (Exploitation, hours/days later):
  Attacker IP B (different ASN, residential proxy) → POST /auth/login → JWT used immediately
  [Behavioral baseline reset — no anomaly on IP B]
```

*Supporting indicators:* Authentication from unusual geolocation or ASN, off-hours timestamp, multiple accounts showing same pattern simultaneously, user agent inconsistency between authentication and historical sessions.

*Blast radius:* If this is credential stuffing, the blast radius extends to every resource the compromised account can access. For privileged accounts, this includes data exfiltration, lateral movement, and privilege escalation paths.

---

**Rank 4 — Token Pre-Positioning / Delayed Attack (Probability: ~7%)**
A more sophisticated variant where an authenticated adversary (or malicious insider) obtains a long-lived JWT and intentionally delays use until a planned action window — for example, waiting until after business hours, until a specific data export becomes available, or until defensive monitoring is known to be reduced (e.g., holiday periods). This is particularly relevant for JWTs with long expiration windows (24h+).

*Risk amplifier:* If the JWT is stateless (no server-side session record) and has a long `exp` claim, the token remains valid regardless of subsequent password changes or account lockouts unless an explicit revocation mechanism (blocklist/denylist) exists.

---

**Rank 5 — Application or Client-Side Error (Probability: ~4%)**
A bug in the client application causes the token to be issued but not stored correctly (e.g., written to a storage location the app cannot subsequently read, dropped due to a race condition, or lost due to a page redirect before the token is persisted). The user may re-authenticate successfully on a second attempt.

*Supporting indicators:* User re-authenticates within minutes of the first event, same device/IP, no other anomalies.

---

**Rank 6 — Insider Threat Reconnaissance (Probability: ~2%)**
An insider authenticates to a system outside their normal workflow — possibly to verify they still have access before exfiltrating data or to test whether their account has been flagged. The lack of subsequent activity may indicate they decided not to proceed, or that they are operating cautiously.

*Supporting indicators:* Authentication to systems outside the user's normal access pattern, unusual time of day, recent HR events (performance review, termination notice, role change).

---

### For the Detector Anomaly (`scanned: 0`)

**Rank 1 — Data
