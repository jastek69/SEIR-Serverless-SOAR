# SOAR Report - unused-token-eventbridge-scheduler-1781384642 - 2026-06-13_21-04-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T21:04:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and an empty `findings_sample`. This means the detector ran but found **nothing to analyze** — either because no tokens existed in the monitored scope, or because the detection pipeline itself has a fault.

This discrepancy is itself a security-relevant finding and will be treated as a primary concern throughout this analysis.

---

## 1. Severity Assessment

### Overall Severity: **MEDIUM** (with escalation potential to HIGH)

| Dimension | Rating | Justification |
|---|---|---|
| Immediate Threat | LOW | No confirmed malicious activity; no token was used |
| Detection Integrity Risk | HIGH | Scanner returned zero scanned records — suggests blind spot |
| Operational Risk | MEDIUM | If legitimate, indicates UX/flow issues; if malicious, recon activity |
| Data Exposure Risk | LOW–MEDIUM | Token unused limits blast radius, but issuance itself has value to attackers |
| Compliance Risk | MEDIUM | Unused credential issuance may violate least-privilege and audit requirements |

### Justification

The core event — a JWT issued but never used — sits at an interesting intersection of **benign user behavior** and **adversarial reconnaissance**. On its own, an unused token is low severity. However, the **detector returning zero scanned records** elevates this significantly because:

- A detection system that scans nothing provides **false assurance**
- If this is a systemic failure, **all unused token events are invisible** to the SOC
- Adversaries who understand your detection cadence can exploit the 5-minute threshold window deliberately
- The mismatch between the described event and the JSON output suggests either a **logging pipeline failure**, **misconfigured scope**, or **intentional evasion**

The blast radius of an unused JWT, while currently contained, depends heavily on the token's claims — if it carries elevated privileges (admin, write scopes, cross-service access), the risk profile increases substantially even without observed use.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Detector/Pipeline Misconfiguration (Most Likely)
**Probability: ~55%**

The `scanned: 0` value is the most anomalous data point. In a healthy system processing even a single authentication event, the scanner should have at minimum one record to evaluate.

**Evidence supporting this:**
- `findings_total: 0` combined with `scanned: 0` is logically consistent only if the input dataset was empty
- EventBridge Scheduler invoked the detector correctly (trigger source confirmed), meaning the scheduling layer worked
- The fault likely lies in the **data ingestion layer** — the query or data source feeding the detector returned no rows

**Possible root causes:**
- Token store query has a bug (wrong table, wrong time window, wrong index)
- Token records are written to a different partition/region than the scanner reads from
- IAM permissions on the scanner Lambda/service prevent reading the token store
- Token TTL or cleanup job ran before the scanner could read records
- The `threshold_minutes: 5` in the detector conflicts with the `15 minutes` described in the event narrative — the scanner may be looking at the wrong time window

---

### Rank 2 — Legitimate User Abandonment (Benign)
**Probability: ~25%**

Users authenticate and then abandon sessions regularly due to:
- Distraction or interruption after login
- Multi-tab browsing where the authenticated tab was closed
- Password manager auto-filling credentials on a page the user didn't intend to use
- Mobile app backgrounding causing session initialization without completion
- OAuth/OIDC flows where the user closed the browser before the redirect completed

**Why this is still worth investigating:**
Even benign abandonment at scale can indicate UX friction that drives users to re-authenticate repeatedly, generating token churn that obscures malicious patterns.

---

### Rank 3 — Automated Credential Validation / Stuffing Probe
**Probability: ~12%**

Attackers running credential stuffing campaigns often authenticate to **validate credentials** without proceeding further. The pattern is:
1. Submit credentials → receive 200 OK + JWT
2. Record the credential as "valid"
3. Move on — the token is never needed; the goal was validation

**Indicators that would elevate this:**
- Authentication came from a datacenter IP, VPN, or Tor exit node
- User-agent string is non-standard or headless browser signature
- Authentication velocity is higher than normal for this user
- Geographic anomaly (login from unexpected country/region)
- The user has no prior history of session abandonment

**Blast radius if confirmed:** The attacker now has a verified credential pair. Future attacks can use these credentials for account takeover, lateral movement, or sale on dark web markets.

---

### Rank 4 — Automated Service/Bot Authentication Without Follow-Through
**Probability: ~5%**

Internal or external services sometimes authenticate to obtain tokens for health checks, monitoring probes, or misconfigured automation that doesn't complete its intended workflow. This is benign but indicates operational hygiene issues.

---

### Rank 5 — Deliberate Evasion of Detection Thresholds
**Probability: ~3%**

A sophisticated adversary aware of your 5-minute unused token detection threshold might authenticate, wait just under the threshold, use the token minimally, then discard it — or conversely, authenticate and deliberately not use the token to probe whether alerts fire. The `threshold_minutes: 5` in the JSON vs. `15 minutes` in the narrative description is a potential indicator that someone has tested your detection boundaries.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

**Step 1: Validate the Detector Pipeline**
This is the highest priority. A detector that scans zero records is a detection gap, not a clean bill of health.

```
Priority: CRITICAL
Owner: SOC Engineer / Detection Engineering
```

- Query the token store directly (database, Redis, DynamoDB, etc.) and confirm whether tokens exist in the expected time window
- Review CloudWatch Logs (or equivalent) for the `unused_token_detector` Lambda execution — look for errors, empty query results, or permission denials
- Verify the IAM role attached to the detector has `read` permissions on the token store
- Confirm the EventBridge Scheduler is passing the correct parameters (especially `threshold_minutes`)
- Cross-reference the `threshold_minutes: 5` in the detector config against the `15 minutes` described in the event — determine which is authoritative

**Step 2: Locate the Specific Authentication Event**
Independently of the detector, find the authentication event described:

- Query your auth service logs for successful authentications in the relevant time window
- Identify the specific JWT issued: extract `sub` (user ID), `iat` (issued at), `exp` (expiry), `scope`/`roles`, and `jti` (token ID)
- Check token usage logs — confirm the token was truly never used, or determine if usage occurred outside the monitored scope

**Step 3: Enrich the Authentication Event**

```
For the identified authentication event, collect:
- Source IP address → run through threat intel (VirusTotal, Shodan, AbuseIPDB)
- Geolocation → compare against user's historical login locations
- User-Agent string → identify if browser, mobile, or automated client
- Authentication method →
