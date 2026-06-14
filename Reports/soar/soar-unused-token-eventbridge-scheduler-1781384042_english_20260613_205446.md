# SOAR Report - unused-token-eventbridge-scheduler-1781384042 - 2026-06-13_20-54-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:54:02Z
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
# Security Event Analysis: Unused JWT Token After Authentication

---

## Preliminary Note on Event Context

Before proceeding with the full analysis, a **critical observation** must be surfaced: the provided JSON context reveals `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector itself **produced no findings** — it ran but examined zero records. This is a significant **detection infrastructure anomaly** that materially changes the analysis. The event described in the scenario (user authenticated, JWT issued, token unused for 15 minutes) is the *hypothetical trigger pattern* this detector is designed to catch, but the detector is currently **not functioning as intended**. Both the behavioral pattern and the detector failure must be analyzed.

---

## 1. Severity Assessment

### Behavioral Pattern Severity: 🟡 **MEDIUM** (with escalation potential to HIGH)

### Detector Failure Severity: 🔴 **HIGH**

---

### Behavioral Pattern Justification

An authentication event followed by a JWT issuance with zero subsequent token usage within the defined threshold window is an **anomalous but ambiguous signal**. On its own, it sits at **Medium** severity because:

| Factor | Assessment |
|---|---|
| Confirmed compromise | No — authentication succeeded, suggesting valid credentials |
| Credential abuse signal | Moderate — valid auth with no follow-through is a known recon/testing pattern |
| Data exfiltration evidence | None at this stage |
| Blast radius (if malicious) | Depends entirely on the token's scope and claims |
| Frequency context | Single event — insufficient for high confidence |

The severity **escalates to High** if any of the following are true:
- The authenticating account holds elevated privileges (admin, service account, IAM roles)
- The authentication originated from an anomalous IP, geolocation, or ASN
- The account has no prior history of this behavioral pattern
- Multiple accounts exhibit this pattern simultaneously (credential stuffing sweep)
- The token contains broad audience (`aud`) claims or long expiry (`exp`) values

### Detector Failure Justification (HIGH)

A security control that executes but scans zero records represents a **silent failure** — the most dangerous class of detection gap. The system *believes* it is protected; it is not. This is rated High because:

- The detection gap is **systematic**, not event-specific
- It creates a **false assurance** that unused token activity is being monitored
- Any malicious activity matching this pattern would go **completely undetected**
- The failure mode is invisible without explicit monitoring of the detector itself

---

## 2. Possible Explanations Ranked by Likelihood

### For the Behavioral Pattern (Token Issued, Never Used)

---

#### 🥇 Rank 1 — Benign User Abandonment (Likelihood: ~45%)

**Description:** The user authenticated (e.g., clicked "Login"), received a token, and then abandoned the session — closed the browser tab, got distracted, navigated away, or experienced a client-side error before making an authenticated API call.

**Supporting indicators:**
- Single occurrence
- Business hours timestamp
- No prior anomalous activity on the account
- Token issued via interactive login flow (not programmatic)

**Risk level:** Low. No action required beyond logging.

---

#### 🥈 Rank 2 — Automated Credential Validation / Credential Stuffing Probe (Likelihood: ~25%)

**Description:** An adversary with a list of compromised credentials is testing which credentials are valid without triggering downstream activity. The pattern — authenticate, receive token, discard — is a deliberate technique to validate credentials while minimizing behavioral footprint. The adversary may return later or sell confirmed valid credentials.

**Attack path:**
```
Adversary obtains credential list (breach database, phishing, etc.)
        ↓
Automated tool iterates credentials against /auth endpoint
        ↓
Successful auth → JWT issued → tool records "valid credential"
        ↓
No API calls made (avoids triggering rate limits, WAF rules, anomaly detection)
        ↓
Adversary returns later for targeted exploitation OR sells validated list
```

**Supporting indicators:**
- Authentication from unusual IP/ASN/geolocation
- High volume of auth attempts across multiple accounts in short window
- User-agent string anomalies (scripted clients, headless browsers)
- Authentication outside normal user hours
- No MFA challenge (or MFA bypass)

**Blast radius:** Moderate to High. Confirmed valid credentials can be leveraged for account takeover, lateral movement, or privilege escalation depending on account role.

---

#### 🥉 Rank 3 — Broken or Misconfigured Client Application (Likelihood: ~20%)

**Description:** A service account, CI/CD pipeline, or application component authenticated successfully but failed to use the token due to a bug, misconfiguration, or deployment issue. Common in microservice architectures where token injection into downstream requests is handled separately from authentication.

**Examples:**
- A Lambda function authenticates but crashes before making downstream calls
- A mobile app authenticates but fails to persist the token to local storage
- A service mesh sidecar drops the Authorization header
- A deployment pipeline authenticates to fetch secrets but the secret-fetching step fails

**Supporting indicators:**
- Service account or non-human identity as the authenticating principal
- Consistent pattern at the same time intervals (scheduled job)
- Correlated application errors in adjacent logs
- Token issued to a known service identity

**Risk level:** Low security risk, High operational risk. Indicates a broken workflow that may cause service degradation.

---

#### Rank 4 — Token Pre-Issuance / Warming Pattern (Likelihood: ~7%)

**Description:** Some architectures pre-issue tokens during session initialization or warm-up phases, storing them for later use. If the "use" occurs via a different mechanism not captured in the token usage log (e.g., token passed server-side, used in a different service boundary), it may appear unused.

**Risk level:** Low. Primarily a detection tuning issue.

---

#### Rank 5 — Insider Threat / Deliberate Reconnaissance (Likelihood: ~3%)

**Description:** A malicious insider or compromised internal account authenticates to confirm access is still active without triggering activity-based alerts. Less likely as a first-order explanation but must be considered for privileged accounts.

**Supporting indicators:**
- Privileged account (admin, DBA, finance)
- Authentication outside normal working hours
- Recent HR events (termination notice, disciplinary action, role change)
- Prior anomalous data access patterns

---

### For the Detector Failure (scanned: 0)

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | Token storage query returning empty result set (wrong table, index, time window filter bug) | 40% |
| 2 | EventBridge Scheduler firing before token records are written (race condition / propagation delay) | 25% |
| 3 | IAM/permissions issue preventing the detector Lambda from reading the token store | 20% |
| 4 | Token store is empty because tokens are not being persisted at all (architectural gap) | 10% |
| 5 | Detector deployed to wrong environment/region | 5% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Investigate the detector failure BEFORE investigating the behavioral pattern.
A broken detector means you have no visibility into the scope of the behavioral pattern.
```

**Step 1: Triage the detector infrastructure**
- [ ] Review CloudWatch Logs for the `unused_token_detector` Lambda execution
- [ ] Confirm the
