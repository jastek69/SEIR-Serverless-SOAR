# SOAR Report - unused-token-eventbridge-scheduler-1781464396 - 2026-06-14_19-13-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:13:16Z
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

Before proceeding with the full analysis, a **critical observation** must be surfaced: the provided JSON context reveals `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector itself **produced no findings** — and more importantly, **scanned zero records**. The narrative description of the event (authenticated user, JWT issued, token unused within 15 minutes) describes the *intended detection scenario*, but the telemetry shows the detector **did not execute meaningfully**. This duality — a detector that fired but found nothing because it scanned nothing — is itself a security concern and is treated as a primary finding throughout this analysis.

---

## 1. Severity Assessment

### Overall Severity: **MEDIUM** (with escalation potential to HIGH)

| Dimension | Rating | Justification |
|---|---|---|
| Immediate Threat | LOW | No confirmed malicious activity; no tokens confirmed unused |
| Detection Integrity | HIGH | Scanner processed 0 records — detection capability is blind |
| Operational Risk | MEDIUM | If real unused tokens exist, they are currently undetected |
| Blast Radius | MEDIUM-HIGH | Undetected issued-but-unused tokens represent latent credential exposure |
| Confidence in Clean State | VERY LOW | Zero scanned ≠ zero findings; it means the check never ran properly |

### Justification Narrative

The scenario as described — a user authenticates, receives a JWT, and never uses it — sits at an interesting intersection of **benign user behavior** and **credential harvesting tradecraft**. In isolation, a single unused token is low severity. However, the detector reporting `scanned: 0` means the organization currently has **no visibility** into whether this pattern is occurring at scale. A threat actor performing credential stuffing, session token harvesting via phishing, or OAuth abuse would generate exactly this signature: valid authentication followed by token issuance, with the token exfiltrated and held for later use or sold. The inability to detect this at scale elevates the severity of the *detection gap* to HIGH.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Detector Misconfiguration or Data Source Failure *(Likelihood: Very High)*

The `scanned: 0` result is the most immediately actionable finding. Possible causes:

- The EventBridge Scheduler triggered the Lambda/function correctly, but the downstream query (DynamoDB, Redis, RDS, etc.) returned an empty result set due to a misconfigured query, wrong table/index, incorrect time window filter, or IAM permission denial on the data source.
- The token store was queried with a filter that excluded all records (e.g., `WHERE issued_at < NOW() - INTERVAL 5 MINUTES` with a timezone mismatch).
- The detector was recently deployed and the token issuance events are written to a different data store than the one being scanned.
- A silent exception was caught and swallowed, causing the function to exit cleanly with zero results rather than raising an error.

**Why this ranks first:** The JSON is unambiguous. Zero scanned in a production environment with active users is statistically implausible unless the system is brand new or the data pipeline is broken.

---

### Rank 2 — Benign User Behavior (Abandoned Session) *(Likelihood: High — for the described scenario)*

A user authenticates (e.g., clicks a "Login" button), receives a JWT, and then:

- Closes the browser tab immediately after login.
- Experiences a client-side JavaScript error that prevents the token from being stored or used.
- Navigates away before the SPA (Single Page Application) completes initialization.
- Authenticates via a mobile app that crashes before making its first authenticated API call.
- Uses a "remember me" flow that pre-authenticates but defers actual usage.

This is the most common real-world explanation for individual unused token events and represents **no security threat**.

---

### Rank 3 — Automated Credential Validation / Stuffing *(Likelihood: Medium)*

Threat actors running credential stuffing operations often:

1. Submit stolen username/password pairs against the authentication endpoint.
2. Collect the resulting JWT to **validate** that the credential is live.
3. Store the token (or just the validated credential) for later use or sale.
4. Never actually use the token against the application's business logic endpoints.

This produces exactly the described signature: successful auth → JWT issued → token never used. At scale, this pattern is a strong indicator of automated credential validation. The attacker's goal is credential inventory, not immediate account takeover.

**Attack path detail:**
```
Attacker → Auth Endpoint (POST /login with stuffed creds)
         → Receives 200 OK + JWT
         → Logs credential as "valid"
         → Moves to next credential pair
         → JWT expires unused
```

**Detection gap:** Without the unused token detector functioning, this campaign would be entirely invisible in application logs, as the auth endpoint returns 200 for each valid credential — indistinguishable from legitimate logins.

---

### Rank 4 — Phishing / Token Harvesting *(Likelihood: Medium)*

A user is directed to a convincing phishing page that:

1. Proxies the real authentication flow (adversary-in-the-middle, e.g., Evilginx2-style).
2. Captures the issued JWT in transit.
3. Redirects the user to an error page or the real application without the token.

The legitimate user never uses the token (they see an error or re-authenticate). The attacker holds the token for later use. The unused token window (5–15 minutes) may be the attacker's operational delay before using the harvested token.

---

### Rank 5 — Service Account / API Client Misconfiguration *(Likelihood: Medium-Low)*

An automated service or CI/CD pipeline:

- Authenticates to obtain a JWT as part of a health check or smoke test.
- Fails to proceed to the next step due to a bug, network timeout, or configuration error.
- Leaves the token unused.

This is benign but indicates a broken automation pipeline that should be investigated separately.

---

### Rank 6 — Reconnaissance / Application Fingerprinting *(Likelihood: Low)*

An attacker probing the application may authenticate with a test or compromised account to:

- Decode the JWT and extract claims (issuer, audience, algorithm, custom claims, user roles).
- Map the application's authentication architecture.
- Identify token expiry windows, signing algorithms (especially if `alg: none` or weak algorithms are used).

The token is never used against business logic — only decoded and analyzed.

---

### Rank 7 — Insider Threat / Privilege Escalation Staging *(Likelihood: Low)*

A malicious insider authenticates with a secondary account or service account to:

- Obtain a token with elevated privileges.
- Stage it for use at a specific time (e.g., after hours, during a maintenance window).
- Avoid using it immediately to evade real-time monitoring.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–2 Hours)

#### Action 1: Diagnose the Detector Failure

This is the **highest priority action**. The detector is blind.

```
CHECKLIST:
[ ] Review CloudWatch Logs for the Lambda function invoked by EventBridge
[ ] Confirm the function received the trigger event (check invocation logs)
[ ] Identify the data source being queried (DynamoDB table, Redis key pattern, RDS query)
[ ] Manually execute the underlying query against the data
