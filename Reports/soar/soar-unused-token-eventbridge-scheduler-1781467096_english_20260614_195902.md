# SOAR Report - unused-token-eventbridge-scheduler-1781467096 - 2026-06-14_19-58-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:58:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This means the security event description (user authenticated, JWT issued, token unused within 15 minutes) represents either a *hypothetical trigger scenario* used to configure/test the detector, or a **metadata/pipeline integrity issue** where the detector ran but failed to ingest data. Both scenarios carry independent security implications that will be addressed throughout this analysis.

The analysis will cover **both dimensions**:
- The *behavioral pattern* described (unused JWT after authentication)
- The *detector health anomaly* revealed in the JSON

---

## 1. Severity Assessment

### Overall Severity: **MEDIUM** (Behavioral Pattern) | **HIGH** (Detector Integrity Failure)

---

### 1a. Behavioral Pattern — Unused JWT After Authentication

| Dimension | Assessment |
|---|---|
| **Severity** | MEDIUM |
| **Confidence** | LOW-MEDIUM (insufficient data volume per JSON) |
| **CVSS Proxy Score** | ~5.5 (AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:L/A:N) |
| **MITRE ATT&CK Mapping** | T1078 (Valid Accounts), T1539 (Steal Web Session Cookie), T1550.001 (Use Alternate Authentication Material) |

**Justification:**

An authentication event that produces a JWT but results in zero subsequent API calls within the threshold window is an anomalous behavioral signal. Under normal usage patterns, a user who authenticates has an immediate intent — accessing a resource, performing an action, or initiating a session. The absence of any token usage suggests one of several threat scenarios:

- **Credential validation probing**: An adversary may be testing whether stolen credentials are valid without triggering downstream activity-based detections. This is a deliberate evasion technique — authenticate to confirm credential validity, then use the token later from a different context or infrastructure.
- **Token harvesting for offline use**: The JWT may have been issued and exfiltrated for use outside the monitored environment (e.g., replayed against a microservice not covered by the detector's scope).
- **Automated credential stuffing with success confirmation**: Tooling that performs credential stuffing often logs successful authentications separately from exploitation, creating exactly this pattern at scale.

The severity is capped at MEDIUM for the behavioral pattern alone because:
1. There are legitimate explanations (see Section 2)
2. No confirmed exploitation has occurred
3. The blast radius depends heavily on the JWT's scope (claims, audience, expiry)

However, if this pattern is observed **at scale** (multiple accounts, short time windows, originating from similar IP ranges or ASNs), severity escalates to **HIGH-CRITICAL** immediately.

---

### 1b. Detector Integrity Failure — Zero Scanned Records

| Dimension | Assessment |
|---|---|
| **Severity** | HIGH |
| **Confidence** | HIGH |
| **Impact** | Detection blind spot — unknown scope |

**Justification:**

The JSON shows `"scanned": 0` with `"findings_total": 0`. A detector that scans zero records cannot produce valid findings. This is not a clean bill of health — **it is a silent failure**. The detector was invoked by EventBridge Scheduler, confirmed execution, but processed no data. This creates a **detection gap of unknown duration**, meaning:

- Any unused token events that occurred during this window were not evaluated
- The security team has a false sense of coverage
- An adversary who understands your detection cadence (e.g., through prior reconnaissance or insider knowledge) could time activity to exploit scheduler gaps

This is analogous to a security camera that powers on, records a black screen, and reports "no incidents observed."

---

## 2. Possible Explanations Ranked by Likelihood

### For the Behavioral Pattern (Unused JWT)

---

**Rank 1 — Benign: User Abandoned Session (Most Likely, ~45%)**

The user authenticated but was interrupted before using the application — a phone call, a browser crash, navigating away, or simply changing their mind. This is the most statistically common explanation in environments with low-friction authentication (SSO, biometric, passwordless). The signal-to-noise ratio for this explanation is high in consumer-facing applications and low in API-only or internal tooling environments.

*Distinguishing indicators:*
- Single occurrence for this user
- Authentication occurred during business hours
- User has a history of normal session activity
- No geographic or device anomalies

---

**Rank 2 — Benign: Application or Integration Bug (~25%)**

A service account, CI/CD pipeline, or integration layer authenticated successfully but failed to proceed due to a downstream error (misconfigured redirect URI, token parsing failure, network timeout before first API call). The JWT was issued but the consuming application never received or processed it.

*Distinguishing indicators:*
- Subject (`sub`) claim is a service account or non-human identity
- Authentication occurred outside business hours or in a batch window
- Correlated application errors in the same timeframe
- Repeated pattern across multiple invocations

---

**Rank 3 — Suspicious: Credential Validation Probe (~15%)**

An adversary with a list of potentially valid credentials (obtained via phishing, breach data, or password spraying) authenticates to confirm credential validity without triggering resource-access detections. The JWT is the "receipt" of a valid credential — the adversary may store it, exfiltrate it, or simply mark the account as compromised for later use.

*Distinguishing indicators:*
- Authentication from an unusual IP, ASN, or geolocation
- User-agent string inconsistent with the user's known device profile
- Authentication time outside the user's behavioral baseline
- Multiple accounts showing the same pattern in a short window
- No prior authentication history from this source

*Attack path elaboration:*

```
Adversary obtains credential list (breach/phishing)
        ↓
Automated tool authenticates against target IdP
        ↓
JWT issued → adversary captures token in HTTP response
        ↓
No further requests made (avoids triggering activity-based alerts)
        ↓
Token stored for:
  ├── Later replay within token TTL
  ├── Offline JWT analysis (algorithm confusion, weak secret brute-force)
  └── Credential confirmation → escalate to targeted attack
```

---

**Rank 4 — Suspicious: Token Exfiltration for External Replay (~10%)**

The JWT was issued and immediately exfiltrated to an external system. The adversary intends to use the token outside the monitored environment — against a microservice, internal API, or resource that the detector does not cover. This is particularly dangerous in environments with broad JWT audience (`aud`) claims or where the same JWT is accepted by multiple services.

*Blast radius consideration:*
If the JWT contains broad scopes or is accepted by multiple services (common in microservice architectures with shared signing keys), a single exfiltrated token could grant access to numerous systems. The blast radius scales directly with:
- Token TTL (longer = more exposure window)
- Scope breadth (admin vs. read-only)
- Number of services accepting the token
- Whether token revocation infrastructure exists

---

**Rank 5 — Malicious: Automated Credential Stuffing at Scale (~5%)**

At low frequency, this looks like Rank 3. At scale, this is a coordinated credential stuffing campaign where the authentication success rate is being measured. The unused token pattern across many accounts in
