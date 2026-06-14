# SOAR Report - unused-token-eventbridge-scheduler-1781384342 - 2026-06-13_20-59-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:59:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the provided JSON context.** The JSON shows:

- `scanned: 0` — No tokens were actually scanned
- `alerted: 0` — No alerts were generated
- `findings_total: 0` — No findings exist
- `findings_sample: []` — Empty findings array
- `threshold_minutes: 5` — The detector threshold is 5 minutes, not 15

This discrepancy is itself a security-relevant finding. The analysis below addresses **both** the described scenario and the **meta-finding** of detector malfunction, as the latter may be the more operationally urgent issue.

---

## 1. Severity Assessment

### Scenario A: Unused JWT Token (Described Narrative)
**Severity: LOW to MEDIUM (Contextual)**

| Factor | Assessment |
|---|---|
| Standalone signal | Low severity — single unused token is common benign behavior |
| In aggregate or correlated | Medium — pattern across users elevates concern |
| Combined with other IOCs | Potentially High — depends on correlated signals |
| Data sensitivity of protected resources | Escalates severity if token grants access to sensitive scopes |

**Justification:**

An authenticated session that produces a JWT which is never exercised is a weak signal in isolation. Users abandon sessions, close browsers, experience network interruptions, or authenticate via automated scripts that fail post-auth. However, this pattern becomes analytically significant when:

- It occurs repeatedly for the same account (credential stuffing probe — authenticate to validate credentials, discard token)
- It occurs across many accounts in a short window (automated enumeration)
- The authentication method used was atypical (new device, new geography, new ASN)
- The token carries elevated privilege scopes

The **blast radius** of an unused token is theoretically zero — no resources were accessed. However, the *authentication event itself* confirms valid credentials exist and were successfully used, which has intelligence value to an adversary.

---

### Scenario B: Detector Producing Zero Scans (JSON Context)
**Severity: MEDIUM to HIGH**

| Factor | Assessment |
|---|---|
| Detection gap created | High — blind spot in token monitoring |
| Duration of gap unknown | Potentially extended if scheduler misconfigured |
| Tokens that should have been flagged | Unknown — zero scanned means zero visibility |
| Compliance implications | Medium-High depending on regulatory framework |

**Justification:**

A detector that fires (is invoked by EventBridge Scheduler) but scans zero records represents a **silent failure** — the most dangerous class of security control failure. The system *appears* healthy (no alerts, no errors surfaced to operators) while providing zero actual coverage. This is categorically worse than a detector that fails loudly.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused JWT Token Pattern

**Rank 1 — Benign User Behavior (Probability: ~60%)**
> User authenticated, was interrupted, closed the browser tab, experienced a UI error, or the client application failed to make the first API call. This is the most statistically common explanation. Users frequently authenticate to web applications and abandon the session before meaningful interaction.

**Rank 2 — Automated Script / Service Account Failure (Probability: ~20%)**
> A CI/CD pipeline, scheduled job, or service account authenticated successfully but the downstream process that would consume the token failed (exception, misconfiguration, dependency unavailable). The token was issued but the consuming process never ran.

**Rank 3 — Credential Validation Probe — Credential Stuffing (Probability: ~10%)**
> An adversary using a credential stuffing tool authenticates to confirm that a username/password combination is valid. The goal is credential validation, not session use. The token is discarded because the adversary's objective (confirming the credential works) is already achieved. This is a well-documented technique used to build validated credential lists for sale or targeted attack.

*Supporting indicators to look for:*
- High volume of similar events across different accounts
- Authentication from datacenter/VPS/residential proxy IP ranges
- User-agent strings associated with automation tools
- Authentication attempts clustered in time
- Accounts with no prior authentication history suddenly appearing

**Rank 4 — Token Exfiltration with Deferred Use (Probability: ~5%)**
> An adversary has compromised the authentication flow (e.g., man-in-the-browser, malicious browser extension, compromised client) and exfiltrated the JWT for use from a different system. The 15-minute window may not capture deferred use if the token has a longer TTL. This is lower probability but higher impact.

*Supporting indicators:*
- Token later used from a different IP/device than the authentication event
- Authentication from a known-clean endpoint, token use from anomalous endpoint
- Token used after the user's normal working hours

**Rank 5 — Application Bug / Race Condition (Probability: ~4%)**
> The application issued a token but a client-side bug, race condition, or misconfigured redirect prevented the token from being stored or used. The user may have experienced a silent failure and re-authenticated.

**Rank 6 — Reconnaissance / Application Fingerprinting (Probability: ~1%)**
> An adversary authenticated to confirm the authentication endpoint works, gather response headers, understand token format/claims, or map the application's authentication behavior. Token use is not the objective.

---

### For the Zero-Scan Detector (JSON Context)

**Rank 1 — Data Source / Query Misconfiguration (Probability: ~45%)**
> The detector's underlying query (DynamoDB scan, database query, cache lookup) is targeting the wrong table, index, partition key, or time window. The query executes successfully but returns zero records because it's looking in the wrong place.

**Rank 2 — Token Storage Pipeline Failure (Probability: ~25%)**
> Tokens are not being written to the store that the detector queries. An upstream change (deployment, configuration drift, IAM permission change) broke the write path, so the read path finds nothing.

**Rank 3 — EventBridge Scheduler Misconfiguration (Probability: ~15%)**
> The scheduler is invoking the Lambda/function with incorrect parameters, wrong environment variables, or a stale configuration that points to a non-existent or empty data source.

**Rank 4 — IAM / Permissions Regression (Probability: ~10%)**
> The detector function lost read permissions to the token store. Rather than throwing an exception (which would be caught), it may be silently returning empty results if the SDK call is improperly error-handled.

**Rank 5 — Intentional Suppression / Insider Threat (Probability: ~5%)**
> A malicious insider or compromised deployment pipeline modified the detector to suppress findings. This is low probability but must be considered given the security implications of a silently disabled detector.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### For the Detector Malfunction (Priority 1)

```
[ ] 1. Verify EventBridge Scheduler execution logs in CloudWatch
        - Confirm the Lambda was actually invoked
        - Check for throttling, timeout, or error events
        - Validate the invocation payload matches expected schema

[ ] 2. Check Lambda execution logs for the unused_token_detector function
        - Look for silent exceptions caught and swallowed
        - Verify environment variables (table names, region, thresholds)
        - Check for IA
