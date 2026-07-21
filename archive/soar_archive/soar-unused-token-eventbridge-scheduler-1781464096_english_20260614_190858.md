# SOAR Report - unused-token-eventbridge-scheduler-1781464096 - 2026-06-14_19-08-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:08:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector ran but found **nothing to analyze** — no tokens were scanned at all.

This discrepancy is itself a security-relevant finding and will be treated as a primary concern throughout this analysis. The analysis will address **both** the hypothetical event described in the narrative **and** the detector malfunction indicated by the JSON.

---

## 1. Severity Assessment

### Narrative Event (Unused JWT Token)
| Attribute | Value |
|---|---|
| **Severity** | LOW–MEDIUM (Informational with escalation potential) |
| **Confidence** | LOW (insufficient data to confirm malicious intent) |
| **Urgency** | LOW (no active exploitation confirmed) |

**Justification:**
An authenticated session where a JWT is issued but never used is a weak signal in isolation. It becomes meaningful only in aggregate or when correlated with other behavioral indicators. A single occurrence has a high base rate of benign explanation (user closed browser, network drop, bot scan, etc.). However, at scale or in combination with credential stuffing indicators, it can represent a reconnaissance or token-harvesting pattern.

### JSON Context Finding (Detector Malfunction)
| Attribute | Value |
|---|---|
| **Severity** | HIGH |
| **Confidence** | HIGH |
| **Urgency** | HIGH |

**Justification:**
A detector that fires but scans zero records represents a **silent failure in a security control**. This is categorically more dangerous than the event it was designed to detect. If `scanned: 0` reflects a persistent state rather than a transient empty window, the organization has a detection gap of unknown duration. Attackers who have discovered this gap can issue and use tokens freely without triggering any alerting. The blast radius of a broken detector is the entire JWT-authenticated attack surface.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Narrative Event (Unused JWT Token)

#### Rank 1 — Benign User Behavior (Probability: ~60%)
The most statistically likely explanation. The user authenticated and then:
- Closed the browser tab before completing their task
- Was interrupted (phone call, meeting, system crash)
- Authenticated from a mobile device that went to sleep or lost connectivity
- Experienced a client-side rendering failure that prevented the token from being attached to subsequent requests

**Detection gap:** This is indistinguishable from malicious behavior at the individual event level. Volume and velocity analysis are required to separate signal from noise.

#### Rank 2 — Automated Credential Validation / Credential Stuffing (Probability: ~20%)
Attackers running credential stuffing campaigns often authenticate to validate credentials without immediately using the session. The workflow is:
1. Submit credential pair to authentication endpoint
2. Receive JWT (confirming valid credentials)
3. Store credential pair in a "valid" list for later exploitation or sale
4. Move on to the next credential pair

The token is never used because the attacker's goal was **validation, not session use**. This pattern is particularly dangerous because:
- It confirms account compromise without triggering post-auth behavioral detections
- The valid credential list may be used days or weeks later from different infrastructure
- Rate limiting on auth endpoints may not catch it if the stuffing is slow and distributed

**Indicators to correlate:**
- Source IP reputation (residential proxy, Tor exit node, known botnet)
- User-agent string anomalies
- Geographic impossibility or velocity
- Multiple accounts authenticated from the same IP within a short window
- Authentication attempts against accounts with no recent login history

#### Rank 3 — Token Harvesting / Session Fixation Preparation (Probability: ~10%)
A more sophisticated attacker may authenticate to obtain a JWT for later use, particularly if:
- The JWT has a long expiration (e.g., 24 hours or more)
- The attacker is waiting for a specific time window (e.g., off-hours) to use the token
- The attacker is testing whether the token survives a logout event (checking for improper token invalidation)

This is a lower-probability but higher-impact scenario. If the JWT is long-lived and the token store does not support server-side revocation, the attacker has a persistent credential that survives password resets if the reset does not invalidate existing tokens.

#### Rank 4 — Automated Security Testing / Penetration Testing (Probability: ~7%)
Internal or authorized external security testing may generate this pattern. Scanners that test authentication endpoints without completing full user flows will produce unused tokens. This should be verifiable against a known testing schedule.

#### Rank 5 — Application Bug / Client-Side Failure (Probability: ~3%)
A bug in the client application may cause the token to be issued but not stored correctly (e.g., failed `localStorage` write, cookie not set due to SameSite policy, CORS issue preventing the token from being returned to the client). The user would experience an authentication failure despite the server issuing a token.

---

### For the JSON Context Finding (Detector Malfunction)

#### Rank 1 — Data Source Disconnection (Probability: ~45%)
The detector is not connected to the token store or authentication event log. Possible causes:
- IAM permission change revoked the detector's read access to the token database or DynamoDB table
- The token storage mechanism changed (e.g., migrated from Redis to DynamoDB) and the detector was not updated
- The EventBridge Scheduler is invoking the correct Lambda ARN but the Lambda's environment variables pointing to the data source are misconfigured or stale

#### Rank 2 — Empty Time Window / Race Condition (Probability: ~25%)
The scheduler fired during a window where no tokens existed in the monitored state (e.g., the token TTL cleanup ran before the detector, or the system is in a low-traffic period). This is benign but should be validated against historical scan counts.

#### Rank 3 — Lambda Execution Error Swallowed (Probability: ~20%)
The Lambda function encountered an error during the scan phase, returned a default/empty result object, and the error was not propagated to the alerting layer. This is a code-level failure where exception handling is too broad.

#### Rank 4 — Intentional Scope Reduction Not Communicated (Probability: ~10%)
A developer changed the query scope (e.g., added a filter that excludes all current tokens) without communicating the change to the security team. The detector runs successfully but against an empty result set by design — a design that was not reviewed for security impact.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

**Action 1: Validate Detector Health — PRIORITY ONE**
```
1. Check CloudWatch Logs for the Lambda function associated with unused_token_detector
2. Verify the last N executions show consistent scanned > 0 values
3. If scanned has been 0 for multiple consecutive runs, escalate as a P1 detection gap
4. Check IAM role attached to the Lambda for required permissions (DynamoDB:Scan, 
   DynamoDB:Query, or equivalent for your token store)
5. Manually invoke the detector with a test token in the monitored state to 
   confirm end-to-end functionality
```

**Action 2: Correlate the Authentication Event**
```
1. Pull the full
