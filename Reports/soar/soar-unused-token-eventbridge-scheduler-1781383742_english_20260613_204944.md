# SOAR Report - unused-token-eventbridge-scheduler-1781383742 - 2026-06-13_20-49-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:49:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON telemetry shows `scanned: 0`, `alerted: 0`, and `findings_total: 0` with an empty `findings_sample` array.** This means the detector itself produced no findings — the alert describes a *scenario* (user authenticated, token issued, token unused within 15 minutes) but the underlying detection pipeline either **did not execute correctly**, **found no matching events**, or **has a data ingestion gap**. This meta-anomaly is itself a security concern and is addressed throughout this analysis.

---

## 1. Severity Assessment

### Rating: **MEDIUM** (with escalation trigger to HIGH if detector malfunction is confirmed)

| Dimension | Assessment |
|---|---|
| **Confidentiality Impact** | Low–Medium (token may have been harvested but not yet used) |
| **Integrity Impact** | Low (no confirmed action taken) |
| **Availability Impact** | Negligible |
| **Likelihood** | Medium (multiple benign explanations exist) |
| **Detection Confidence** | **Low** — zero scanned records is a red flag |

### Justification

The core security concern splits into **two distinct risk vectors**:

**Vector 1 — The Authentication Event Itself**
An issued-but-unused JWT is a weak signal in isolation. However, in aggregate or with enrichment (geo-IP, device fingerprint, time-of-day), it can indicate credential stuffing, token harvesting for deferred use, or automated probing. The 15-minute unused window is meaningful because most legitimate user sessions generate token usage within 30–90 seconds of issuance (page load, API call, etc.).

**Vector 2 — The Detector Malfunction (Higher Concern)**
`scanned: 0` on a scheduled detector is a **detection gap**, not a clean bill of health. If the EventBridge Scheduler fired but the downstream scan logic processed zero records, the organization is operating with a **blind spot** in its token monitoring capability. This is categorically more dangerous than the original event because it means similar events may have gone undetected historically.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Detector/Pipeline Failure *(Most Likely)*
**Probability: ~55%**

The `scanned: 0` value strongly suggests the detector did not successfully query its data source. This could be caused by:

- EventBridge Scheduler fired but the Lambda/ECS task had a cold-start timeout or IAM permission error
- The token store (Redis, DynamoDB, RDS) was unavailable or returned an empty result set due to a query bug
- A recent deployment changed the token schema or table name, breaking the query
- The time window filter in the scan logic has an off-by-one error (e.g., scanning `> 15 minutes` instead of `>= 15 minutes`, or using UTC vs. local time mismatch)
- The detector is newly deployed and the data pipeline feeding it has not yet backfilled

**Why this matters:** If the detector has never worked correctly, every prior "clean" run was a false negative. The blast radius of this gap extends backward in time to the detector's deployment date.

---

### Rank 2 — Legitimate User Abandonment *(Benign, Common)*
**Probability: ~25%**

The user authenticated (possibly via SSO, OAuth, or a login form), a JWT was issued, and the user:

- Closed the browser tab immediately after login
- Was interrupted before completing their workflow
- Authenticated as part of a "remember me" or background refresh flow that doesn't immediately trigger an API call
- Experienced a client-side error (JavaScript crash, network failure) that prevented the token from being attached to subsequent requests

This is the most common real-world explanation for unused tokens in consumer and enterprise applications.

---

### Rank 3 — Automated Credential Validation / Stuffing *(Moderate Concern)*
**Probability: ~10%**

An adversary running a credential stuffing or account takeover (ATO) campaign may:

1. Obtain valid credentials from a breach database
2. Authenticate to validate the credential is active
3. **Not immediately use the token** — instead logging the valid account for later exploitation or sale
4. Return later (potentially outside the 15-minute detection window) to perform malicious actions

This pattern is specifically designed to evade rate-limiting and behavioral detection tools that look for rapid post-authentication abuse. The deferred-use pattern is a known evasion technique documented in MITRE ATT&CK under **T1078 (Valid Accounts)** and **T1110.004 (Credential Stuffing)**.

**Indicators that would elevate this to HIGH:**
- Authentication from a datacenter/VPN/Tor IP
- User-agent string associated with automation (Python requests, curl)
- Authentication time outside the user's historical pattern
- Multiple accounts showing the same unused-token pattern in the same time window

---

### Rank 4 — Token Harvesting / Man-in-the-Middle *(Lower Probability, High Impact)*
**Probability: ~5%**

An adversary intercepted the authentication flow (via phishing, session hijacking, or a compromised client) and obtained the JWT. The legitimate user's session failed (they never received the token), while the attacker holds it for deferred use. The token appears "unused" from the server's perspective because the attacker has not yet acted.

**Why this is dangerous despite low probability:** If true, the token is live and the attacker can use it at any time before expiration. Depending on JWT TTL configuration, this window could be minutes or hours.

---

### Rank 5 — Service Account / Bot Authentication Without Immediate Action *(Low, Benign)*
**Probability: ~5%**

A service account or automated process authenticated to pre-warm a token or test connectivity, with the actual workload scheduled to run later. This is poor practice (tokens should be fetched on demand) but not malicious.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Diagnose the detector malfunction BEFORE investigating the auth event.
A broken detector means you cannot trust any historical "clean" results.
```

**Step 1 — Validate Detector Execution**
- Check CloudWatch Logs (or equivalent) for the Lambda/task that the EventBridge Scheduler invoked
- Confirm the function was invoked, completed successfully, and did not throw an exception
- Verify the IAM role attached to the function has `read` permissions on the token store
- Check for throttling events on the token store (DynamoDB read capacity, Redis connection limits)

**Step 2 — Manually Run the Detection Query**
Execute the underlying query the detector should have run, directly against the token store or SIEM:

```sql
-- Example: Find tokens issued but never used within the threshold window
SELECT
    token_id,
    user_id,
    issued_at,
    last_used_at,
    source_ip,
    user_agent,
    DATEDIFF(MINUTE, issued_at, GETUTCDATE()) AS minutes_since_issuance
FROM jwt_token_audit_log
WHERE
    issued_at >= DATEADD(MINUTE, -30, GETUTCDATE())  -- Look back 30 min
    AND (last_used_at IS NULL OR last_used_at = issued_at)
    AND token_status = 'ACTIVE'
ORDER BY issued_at DESC;
```

**Step 
