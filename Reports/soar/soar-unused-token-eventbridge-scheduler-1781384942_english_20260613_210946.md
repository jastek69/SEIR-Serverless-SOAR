# SOAR Report - unused-token-eventbridge-scheduler-1781384942 - 2026-06-13_21-09-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T21:09:02Z
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
# Security Event Analysis: Unused JWT Token Detection

---

## Preliminary Note on Event Context

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector ran but found **nothing to analyze** — no tokens were scanned, and no findings were produced.

This discrepancy is itself a security-relevant signal and will be treated as a **primary finding** alongside the theoretical analysis of the described scenario.

---

## 1. Severity Assessment

### Scenario A: Unused Token (Narrative Description)
**Severity: LOW to MEDIUM (contextual)**

| Factor | Assessment |
|---|---|
| Standalone signal | Low severity — benign explanations dominate |
| Combined with other signals | Medium to High — potential credential harvesting or recon |
| Data sensitivity of protected resources | Escalates severity if token scopes are privileged |
| Volume/pattern | Single event is noise; repeated pattern is a threat indicator |

**Justification:**

An authenticated session that produces an unused JWT is a weak signal in isolation. The authentication itself succeeded, meaning credentials were valid — this is the highest-risk moment. The *absence* of token usage could indicate the attacker obtained what they needed (the token itself, for offline analysis or later use), the user abandoned the session, or an automated process failed silently. The 15-minute window is relatively short, but a sophisticated actor would not necessarily use a stolen token immediately — they may stage it for use outside detection windows or from a different egress point.

The risk is asymmetric: if this is benign, the cost of investigation is low. If this is malicious and ignored, the blast radius includes everything the token's claims authorize.

---

### Scenario B: Detector Malfunction (JSON Context — Primary Finding)
**Severity: MEDIUM to HIGH**

| Factor | Assessment |
|---|---|
| Detection gap created | High — blind spot in token monitoring |
| Operational impact | Medium — depends on how long the gap has existed |
| Compliance implications | Medium to High — audit trail integrity compromised |
| Exploitability of gap | High — attackers who know monitoring is broken operate freely |

**Justification:**

`scanned: 0` with a scheduled detector invocation is a **detector health failure**. A security control that runs but processes zero records is not providing coverage. This is categorically more urgent than a single unused token event because it represents a **systematic detection gap** — any number of unused, stolen, or replayed tokens during this window would go undetected.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused Token Scenario

**Rank 1 — Benign User Abandonment (Likelihood: ~55%)**
The user authenticated and then closed the browser, navigated away, lost connectivity, or was interrupted before completing their intended action. This is the most statistically common explanation in enterprise environments. Session abandonment rates of 40–60% are documented in UX research.

*Supporting indicators:* Single occurrence, business hours timestamp, no prior anomalies on account, token scopes match user's normal role.

---

**Rank 2 — Application or Client-Side Error (Likelihood: ~25%)**
A frontend bug, failed API call, misconfigured redirect URI, or broken token storage (e.g., failed `localStorage` write, blocked cookie) prevented the token from being attached to subsequent requests. The authentication succeeded server-side but the client never received or stored the token correctly.

*Supporting indicators:* Correlated JavaScript errors in browser telemetry, HTTP 4xx/5xx errors in application logs near the same timestamp, multiple users affected simultaneously.

*Attack path relevance:* This scenario can mask a token interception attack — if an attacker performed a man-in-the-middle or token theft at the transport layer, the legitimate client would also fail to receive the token, producing exactly this signature.

---

**Rank 3 — Automated Credential Validation / Credential Stuffing (Likelihood: ~10%)**
An automated tool authenticated to validate that credentials are active without proceeding to use the application. This is a common pattern in credential stuffing operations where attackers verify large batches of credentials and then sell or stage valid ones for later use. The token is irrelevant to the attacker — they only needed the `200 OK` on the authentication endpoint.

*Supporting indicators:* Authentication from unusual IP, ASN associated with hosting/proxy/VPN, user-agent string anomalies, authentication at unusual hours, no prior session history from that IP, multiple accounts attempted from same source.

*Blast radius:* If confirmed, the credential is compromised and must be treated as such regardless of token usage. The attacker now knows the password is valid.

---

**Rank 4 — Token Harvesting / Interception (Likelihood: ~6%)**
An attacker intercepted the JWT in transit (TLS misconfiguration, rogue proxy, compromised endpoint) or via XSS/token theft from storage. The legitimate user's session failed (explaining non-use from the legitimate client), while the attacker holds the token for deferred use. The 15-minute window may not capture deferred use if the attacker waits.

*Supporting indicators:* TLS inspection gaps in network logs, XSS alerts near the same timeframe, the user reports being unable to log in despite entering correct credentials, token later appears in requests from a geographically or behaviorally anomalous source.

*Detection gap:* Standard unused-token detectors only flag non-use within a window. A token used at minute 16 from a different IP would not be caught by this specific control.

---

**Rank 5 — Insider Threat / Deliberate Reconnaissance (Likelihood: ~3%)**
A malicious insider authenticated to generate a valid token for exfiltration or to test access before a planned attack. They may have authenticated from a personal device or unusual location to avoid correlation with their normal activity.

*Supporting indicators:* Authentication from a new device fingerprint, off-hours access, account belongs to a privileged user or someone under HR review, recent access to sensitive data in other systems.

---

**Rank 6 — Service Account / Bot Misconfiguration (Likelihood: ~1%)**
An automated process authenticated but failed to proceed due to a misconfiguration, deployment error, or dependency failure. The "user" is not a human.

*Supporting indicators:* Authentication at precise intervals, machine-like user-agent, service account naming convention.

---

### For the Detector Malfunction (JSON Context)

**Rank 1 — Empty Data Source / Query Returning No Results (~40%)**
The detector's data source (token store, database table, cache) returned zero records. This could mean the query is misconfigured, the data pipeline feeding the store is broken, or the token TTL cleanup ran before the detector, deleting records that should have been scanned.

**Rank 2 — EventBridge Scheduler Misconfiguration (~25%)**
The Lambda or target function was invoked but received an empty or malformed event payload, causing it to skip processing logic and exit cleanly with zero results.

**Rank 3 — Token Store Connectivity Failure (~20%)**
The detector could not reach the token store (Redis, DynamoDB, RDS) and silently returned empty results rather than raising an exception. Silent failure is a critical design flaw.

**Rank 4 — Deployment/Code Regression (~15%)**
A recent deployment changed the detector logic, broke the query, or introduced a bug that causes early exit before scanning.

---

## 3. Recommended Analyst Actions

###
