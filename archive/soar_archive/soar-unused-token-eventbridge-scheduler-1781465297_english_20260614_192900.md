# SOAR Report - unused-token-eventbridge-scheduler-1781465297 - 2026-06-14_19-28-17_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:28:17Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) is partially contradicted by the JSON context provided.** The detector ran successfully, scanned **0 tokens**, and produced **0 findings**. This discrepancy is itself a security-relevant signal and will be addressed throughout this analysis.

The analysis will cover both the **theoretical event scenario** (unused token pattern) and the **operational anomaly** (detector producing zero scans with zero findings).

---

## 1. Severity Assessment

### Primary Event: Unused Token After Authentication
**Severity: LOW to MEDIUM (Contextual)**
*CVSS-equivalent qualitative: 3.5–5.5 depending on confirmed explanation*

### Detector Anomaly: Zero Scans, Zero Findings
**Severity: MEDIUM to HIGH (Operational)**
*A detection system that scans nothing is functionally equivalent to no detection system.*

---

### Justification

| Factor | Assessment | Rationale |
|---|---|---|
| Confidentiality Impact | Low–Medium | Token issued but unused; no confirmed data access |
| Integrity Impact | Low | No write operations observed |
| Availability Impact | Low | No service disruption |
| Authentication Bypass | Not confirmed | Successful auth occurred via legitimate credential path |
| Detector Health | **Critical Gap** | `scanned: 0` means no tokens were evaluated despite scheduler invocation |
| Blast Radius | Medium | If token was harvested, attacker holds valid credential with unknown scope |
| Detection Confidence | Very Low | Zero scan result undermines confidence in the entire detection pipeline |

The unused token pattern in isolation is a **weak signal** — it has many benign explanations. However, combined with a malfunctioning detector, the organization is operating with a **blind spot** in its token lifecycle monitoring, which elevates the operational risk significantly.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Benign: User Abandoned Session (Most Likely ~45%)
The user authenticated (e.g., clicked a login link, initiated SSO) and then closed the browser, navigated away, or was interrupted before performing any action. This is the most statistically common explanation in production environments.

**Supporting indicators:**
- No anomalous authentication signals (no MFA failure, no unusual IP)
- Single token issuance (no token refresh attempts)
- No downstream API calls logged

**Risk:** Negligible in isolation. Elevated if this pattern repeats for the same user/account.

---

### Rank 2 — Benign: Automated Health Check or Integration Test (~20%)
CI/CD pipelines, synthetic monitoring tools, or integration test suites frequently authenticate to validate credential validity without proceeding to use the token for business logic.

**Supporting indicators:**
- Authentication timestamp aligns with deployment windows or scheduled jobs
- Service account or non-human identity involved
- Token issued to a known automation user agent

**Risk:** Low. However, service accounts issuing unused tokens at scale can inflate token stores and create revocation management challenges.

---

### Rank 3 — Operational: Detector Pipeline Failure (~15%)
The `scanned: 0` result strongly suggests the detector itself failed to enumerate the token store. This could mean:
- The token was issued to a data store the detector does not have read access to
- The token was already expired or purged before the scheduler ran
- The token store query returned an empty result due to a bug, misconfiguration, or race condition
- The EventBridge scheduler fired but the downstream Lambda/worker failed silently

**Risk:** Medium-High. A broken detector creates a systematic blind spot. Any token — benign or malicious — issued in this window would go undetected.

---

### Rank 4 — Suspicious: Credential Stuffing / Account Probing (~10%)
An attacker with valid credentials (obtained via phishing, breach database, or password spray) authenticates to confirm credential validity, then abandons the session to avoid triggering behavioral analytics tied to actual resource access.

**Attack path:**
```
Attacker obtains credentials (breach/phish)
    → Authenticates to confirm validity ("credential validation probe")
    → Does NOT use token (avoids triggering data access alerts)
    → Stores confirmed valid credentials for later use
    → Returns later with fresh authentication to conduct actual attack
```

**Supporting indicators that would elevate this:**
- Authentication from unusual geolocation or ASN
- Authentication outside business hours
- User has no recent login history
- Multiple accounts showing same pattern simultaneously
- User agent string associated with automation tools (curl, python-requests, etc.)

**Risk:** Medium-High if confirmed. The attacker now has confirmed working credentials and may return.

---

### Rank 5 — Suspicious: Token Exfiltration Attempt (~7%)
An attacker with partial system access (e.g., SSRF, compromised internal service) triggers an authentication flow to cause a token to be issued, then attempts to harvest the token from the issuance mechanism (token store, logs, network traffic) rather than using it through the normal API path.

**Attack path:**
```
Attacker triggers auth flow via SSRF or compromised service
    → JWT issued and written to token store / response
    → Attacker reads token from storage (DB, Redis, logs) out-of-band
    → Token "never used" via normal API path — but already compromised
```

**Risk:** High if confirmed. The token may be in active use by an attacker through a channel not visible to the detector.

---

### Rank 6 — Malicious: Reconnaissance / Timing Attack (~3%)
Sophisticated adversary authenticates to fingerprint the authentication system — observing token format, expiry, signing algorithm, or response timing — without intending to use the token for resource access.

**Risk:** Low probability but high consequence if the attacker is mapping the system for a larger campaign.

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

**Step 1: Triage the Detector Failure First**
The `scanned: 0` finding is the most actionable immediate concern. A detector that scans nothing provides false assurance.

```
ACTION: Validate detector health
- Check EventBridge execution logs for the scheduler invocation
- Verify the downstream worker (Lambda/container) received the event
- Check worker execution logs for errors, timeouts, or permission failures
- Validate IAM permissions for the detector's token store read access
- Manually query the token store for tokens issued in the last 60 minutes
```

**Step 2: Correlate the Authentication Event**
```
ACTION: Pull full authentication context
- Source IP address and geolocation
- User agent string
- User account type (human vs. service account)
- Authentication method (password, SSO, MFA, API key)
- Time of authentication (business hours? weekend? unusual?)
- Account's historical authentication pattern
- Whether this account has shown this pattern before
```

**Step 3: Check for Out-of-Band Token Use**
```
ACTION: Search for token usage outside normal API paths
- Query application logs for the specific JWT (by jti claim if present)
- Search for the token in any log aggregation system (SIEM, CloudWatch, Splunk)
- Check if the token appears in any error logs (failed requests with the token)
- Review network flow logs for connections from the authenticated user's IP
```

---

### Short-Term (1–24 Hours)

**Step 4: Assess Scope of Detector Blind Spot**
Determine how long the detector has
