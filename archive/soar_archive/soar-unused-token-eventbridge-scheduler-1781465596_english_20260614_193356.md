# SOAR Report - unused-token-eventbridge-scheduler-1781465596 - 2026-06-14_19-33-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:33:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative conflicts directly with the JSON context provided.** The narrative states a token was issued and unused within 15 minutes, yet the JSON telemetry shows:

- `scanned: 0` — no tokens were evaluated
- `alerted: 0` — no alerts were generated
- `findings_total: 0` — no findings exist
- `findings_sample: []` — empty result set
- `threshold_minutes: 5` — the detector threshold is 5 minutes, not 15

This discrepancy is itself a security-relevant finding. The analysis below addresses **both** the theoretical scenario described in the narrative **and** the operational anomaly present in the JSON telemetry, as both warrant investigation.

---

## 1. Severity Assessment

### Narrative Scenario (Unused Token After Auth)
| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟡 **Medium** | Anomalous authentication pattern with no confirmed exploitation |
| **Confidentiality Impact** | Low–Medium | Token could have been used for unauthorized data access |
| **Integrity Impact** | Low | No write operations confirmed |
| **Availability Impact** | Low | No service disruption indicated |
| **Likelihood of Malicious Activity** | Low–Medium | Multiple benign explanations exist but cannot be ruled out |

### JSON Telemetry Anomaly (Detector Producing Zero Scans)
| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🔴 **High** | A security control is silently failing — this is a detection gap |
| **Risk Type** | Operational / Detection Blind Spot | If the detector scanned 0 tokens, it cannot have validated the narrative claim |
| **Blast Radius** | High | Any number of unused/stolen tokens could exist undetected |

> **Key Principle:** A security detector that runs but scans nothing is potentially more dangerous than no detector at all, because it creates false confidence in coverage.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Narrative Event (Token Issued, Never Used)

#### 🥇 Rank 1 — Benign: User Abandoned Session (Most Likely, ~45%)
The user authenticated but navigated away, closed the browser tab, lost connectivity, or was interrupted before completing their intended action. This is the most statistically common explanation in enterprise environments, particularly for web applications with complex login flows.

- **Supporting indicators:** Single auth event, no subsequent API calls, no geographic anomalies
- **Risk level:** Negligible
- **Detection value:** Low signal-to-noise ratio in isolation

#### 🥈 Rank 2 — Benign: Automated Health Check or Integration Test (~20%)
CI/CD pipelines, synthetic monitoring tools, or integration test suites frequently authenticate to verify credential validity without proceeding to use the token for functional operations.

- **Supporting indicators:** Authentication from a service account, non-human user agent, scheduled timing
- **Risk level:** Low, but indicates a potential credential hygiene issue if real credentials are used in tests
- **Detection value:** Should be baselined and suppressed with proper tagging

#### 🥉 Rank 3 — Suspicious: Credential Stuffing / Validity Probe (~15%)
An attacker who has obtained credentials (via breach, phishing, or purchase on dark web markets) may authenticate solely to verify that credentials are valid before using them in a more targeted attack. The token is not used because the attacker's tooling is in a reconnaissance phase — they are building a list of valid accounts.

- **Supporting indicators:** Authentication from unusual IP/ASN, off-hours timing, multiple similar events across accounts, user agent anomalies
- **Attack path:**
  ```
  Credential List Acquisition → Automated Auth Probe → 
  Valid Credential Confirmation → Targeted Exploitation 
  (data exfiltration, privilege escalation, lateral movement)
  ```
- **Blast radius:** If this is credential stuffing at scale, many accounts may be compromised simultaneously
- **Risk level:** High if confirmed

#### Rank 4 — Suspicious: Token Harvesting for Deferred Use (~10%)
An attacker with access to the authentication flow (e.g., via a compromised client device, man-in-the-browser malware, or a rogue application) may capture the issued JWT for use outside the monitored environment. The token appears "unused" because consumption occurs in an unmonitored channel.

- **Supporting indicators:** Token issued to a client that has previously exhibited anomalous behavior, token with long expiry, absence of expected subsequent calls
- **Attack path:**
  ```
  Malware/Rogue App Intercepts Auth Flow → 
  JWT Exfiltrated to Attacker Infrastructure → 
  Token Used Against API from Attacker-Controlled Host → 
  Appears as "Unused" in Original Session Context
  ```
- **Risk level:** High if confirmed — this represents active exploitation with a detection gap

#### Rank 5 — Operational: Application Bug or Misconfiguration (~7%)
A bug in the client application may cause it to authenticate successfully but fail to attach the token to subsequent requests (e.g., token stored in a variable that goes out of scope, incorrect header construction, race condition in async code).

- **Risk level:** Low from a security perspective, but indicates a reliability issue

#### Rank 6 — Suspicious: Insider Threat Reconnaissance (~3%)
A legitimate user authenticates to confirm their access level or test whether their account has been flagged, without proceeding to perform their usual activities.

- **Risk level:** Medium — warrants behavioral baseline comparison

---

### For the JSON Telemetry Anomaly (scanned: 0)

#### 🥇 Rank 1 — Operational: Empty Token Store / No Active Sessions (~40%)
The detector ran but found no tokens in the data store to evaluate. This could be legitimate if the system had no active sessions at scan time, but should be validated against authentication logs.

#### 🥈 Rank 2 — Configuration Error: Incorrect Query or Data Source Pointer (~35%)
The detector is querying the wrong database table, index, wrong time window, or a misconfigured data source. This is a silent failure — the detector reports success but has evaluated nothing meaningful.

#### 🥉 Rank 3 — Security Concern: Detector Suppression or Tampering (~15%)
An attacker with sufficient access may have modified the detector configuration, cleared the token store, or manipulated the EventBridge rule to prevent detection of their activity.

#### Rank 4 — Infrastructure Issue: Data Pipeline Failure (~10%)
Token issuance events are not reaching the data store the detector queries due to a broken pipeline, failed Lambda function, or misconfigured event routing.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### Step 1: Resolve the Telemetry Conflict
```
PRIORITY: CRITICAL — Before any other investigation, determine why 
scanned=0 when the narrative claims a token event occurred.
```

- [ ] Query the authentication log directly: confirm whether the described auth event actually occurred
- [ ] Verify the token store (Redis, DynamoDB, RDS — wherever JWTs are tracked) contains or contained the token in question
- [ ] Check EventBridge rule execution history for the `unused_token_detector` — confirm it fired correctly
- [ ] Review CloudWatch Logs for the detector Lambda/service for errors, exceptions, or empty result sets
