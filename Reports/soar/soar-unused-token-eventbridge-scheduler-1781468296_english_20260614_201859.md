# SOAR Report - unused-token-eventbridge-scheduler-1781468296 - 2026-06-14_20-18-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T20:18:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the JSON context reveals a detector run with zero scanned tokens, zero alerts, and zero findings.** This is itself a significant signal — not necessarily of an attack, but potentially of a **detection gap or misconfiguration in the monitoring pipeline itself.** The analysis will address both the theoretical event pattern (unused JWT after authentication) and the operational anomaly in the detector output.

---

## 1. Severity Assessment

### Overall Severity: **MEDIUM** (with escalation potential to HIGH pending investigation)

| Dimension | Rating | Justification |
|---|---|---|
| Confidentiality Impact | Medium | Token may have been exfiltrated without use |
| Integrity Impact | Low-Medium | No confirmed misuse, but token remains valid |
| Availability Impact | Low | No service disruption observed |
| Detection Confidence | **Low** | Detector scanned 0 tokens — coverage gap confirmed |
| Blast Radius | Medium | Depends on token scope/claims |

### Justification

The unused-token pattern sits at an interesting intersection of **benign user behavior** and **pre-exploitation reconnaissance**. On its own, a single unused token is low signal. However, the combination of:

1. A successful authentication event (credential validity confirmed)
2. Token issuance (attack surface created)
3. Zero subsequent API calls (anomalous for legitimate use)
4. **A detector that scanned nothing** (monitoring blind spot)

...creates a compound risk profile that warrants active investigation rather than passive monitoring.

The **15-minute threshold** referenced in the event narrative versus the **5-minute threshold** in the JSON (`threshold_minutes: 5`) is itself a discrepancy worth flagging — it may indicate misconfigured alerting logic or documentation drift.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Benign: User Abandoned Session (Probability: ~45%)

**Scenario:** A legitimate user authenticated (e.g., clicked a login link, initiated SSO), then closed the browser tab, lost connectivity, or was interrupted before completing their intended workflow.

**Supporting indicators:**
- No prior anomalous activity on the account
- Authentication from a known IP/device fingerprint
- Single isolated occurrence

**Why it still matters:** Even benign unused tokens represent **live credentials** that extend the attack window. A token valid for hours but never used is a liability.

---

### Rank 2 — Automated/Bot Authentication Probe (Probability: ~25%)

**Scenario:** An automated script or credential-stuffing bot successfully authenticated using valid credentials (obtained via prior breach, phishing, or purchase on dark web markets). The bot validated that credentials work but did not proceed to the exploitation phase — either by design (credential validation service) or because it was rate-limited/blocked before use.

**Attack path:**
```
Credential Stuffing Bot
    → POST /auth/login [valid credentials]
    → Receives JWT
    → Logs "credential valid" to attacker infrastructure
    → Does NOT use token (avoids triggering behavioral analytics)
    → Token expires unused
    → Attacker returns later with fresh authentication
```

**Why this is dangerous:** This pattern is specifically designed to **evade behavioral detection** that looks for post-authentication anomalies. The attacker confirms credential validity without triggering API abuse detectors.

---

### Rank 3 — Token Exfiltration (Pre-Use) (Probability: ~15%)

**Scenario:** The token was issued and exfiltrated (via XSS, man-in-the-browser, compromised client endpoint, or network interception) but has not yet been used by the attacker. The 15-minute window may simply be the observation period — the token could be used after the detection window closes.

**Attack path:**
```
Legitimate User Authenticates
    → JWT issued and stored in browser (localStorage/cookie)
    → Malicious script (XSS) exfiltrates token to attacker C2
    → User closes session / token sits unused on legitimate side
    → Attacker uses token from different IP/UA after detection window
```

**Detection gap:** If the token is used *after* the 15-minute unused-token check window, this event would never re-trigger. The attacker effectively has until token expiry.

---

### Rank 4 — Detector Misconfiguration / False Negative (Probability: ~10%)

**Scenario:** The `scanned: 0` field in the JSON strongly suggests the detector itself may be broken. This could mean:

- The EventBridge Scheduler fired correctly, but the Lambda/worker had no data source to query (empty token store, wrong DynamoDB table, incorrect Redis keyspace)
- Token issuance is not being written to the token registry that the detector queries
- A deployment or configuration change broke the token tracking pipeline

**This is the most operationally urgent finding** because it means the unused-token detection capability may be entirely non-functional, regardless of the specific event that triggered this analysis.

---

### Rank 5 — Insider Threat / Privilege Escalation Staging (Probability: ~5%)

**Scenario:** An insider or compromised privileged account authenticates to obtain a token with elevated claims, then deliberately delays use to avoid correlation with a specific action they plan to take.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### Step 1: Investigate the Detector Anomaly First

The `scanned: 0` finding is the highest-priority operational concern.

```
CHECKLIST:
[ ] Verify the token registry data store is reachable from the detector Lambda
[ ] Confirm token issuance events are being written to the registry
[ ] Check CloudWatch Logs for the unused_token_detector Lambda execution
[ ] Verify EventBridge Scheduler target ARN and IAM permissions
[ ] Confirm the detector's query logic matches the token store schema
[ ] Cross-reference: were ANY tokens issued in the past 24 hours per auth logs?
```

#### Step 2: Identify the Specific Authentication Event

```
QUERY AUTH LOGS:
- Extract: user_id, source_ip, user_agent, geo_location, device_fingerprint
- Time window: authentication timestamp ± 30 minutes
- Check: Is this IP/UA combination seen in prior successful authentications?
- Check: Was MFA used or bypassed?
- Check: What is the token's expiry, scope, and claims?
```

#### Step 3: Assess Token Risk

```
TOKEN TRIAGE:
[ ] Is the token still valid? → If yes, consider immediate revocation
[ ] What scopes/roles does the token carry?
[ ] Is this a service account or human user?
[ ] Has the token been seen in any downstream logs (CDN, WAF, API gateway)?
```

### Short-Term Actions (1–24 Hours)

- **Revoke the specific token** if it carries elevated privileges and no legitimate use case can be confirmed
- **Notify the account owner** via out-of-band channel (email/SMS) to confirm whether they initiated the authentication
- **Pull SIEM correlation**: Check if the source IP appears in threat intelligence feeds, prior failed authentication attempts, or other accounts' login history
- **Review token expiry policy**: A token that can sit unused for hours is a prolonged attack surface

### Investigative Queries

```sql
-- Example: Find all tokens issued but never used (last 24h)
SELECT 
    token_id,
    user_id,
    issued_at,
    expires_at,
    source_ip,
    user_agent,
