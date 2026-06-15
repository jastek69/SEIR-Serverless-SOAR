# SOAR Report - unused-token-eventbridge-scheduler-1781464696 - 2026-06-14_19-18-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:18:16Z
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
# Security Event Analysis: Unused JWT Token After Successful Authentication

---

## Preliminary Note: Context Reconciliation

Before proceeding, a critical observation must be surfaced. **There is a material discrepancy between the narrative event description and the JSON context payload.** The narrative describes a specific user authentication event with an unused token, but the JSON telemetry shows:

```json
"scanned": 0,
"alerted": 0,
"findings_total": 0,
"findings_sample": []
```

This means the detector ran but **found nothing to scan** — no tokens were evaluated, no findings were generated. This analysis will address **both layers**:

- **Layer 1:** The theoretical security analysis of the described event pattern (unused JWT after auth)
- **Layer 2:** The operational/detection gap represented by the JSON payload itself, which may be the more urgent concern

---

## 1. Severity Assessment

### Layer 1 — Unused JWT Token Pattern

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟡 **LOW–MEDIUM** | Standalone, this is an anomaly indicator, not a confirmed threat |
| **Confidentiality Risk** | Medium | Token exists and could be intercepted or stolen |
| **Integrity Risk** | Low | No action taken with token yet |
| **Availability Risk** | Low | No service disruption indicated |
| **Escalation Potential** | Medium–High | If credential stuffing or token harvesting, blast radius expands |

**Justification:**

An unused JWT following successful authentication is a **weak signal** in isolation. Its severity is context-dependent and must be correlated with:

- Source IP reputation and geolocation
- Authentication method used (password, MFA, SSO, API key)
- User's historical behavior baseline
- Whether the authentication occurred at an unusual time
- Whether the token was issued to a human user or a service account

The 15-minute unused window crosses the threshold from "user distraction" into **behavioral anomaly territory**, particularly if the application's typical token usage latency is under 30 seconds (as is common in interactive web sessions).

**Blast radius if malicious:**
- Token may have been issued to an attacker who authenticated with stolen credentials
- Attacker may be performing reconnaissance, waiting for an optimal exfiltration window, or the token was harvested for offline use
- If the JWT contains embedded claims (roles, permissions, tenant IDs), the token itself is a portable credential that can be replayed anywhere the signature is trusted

### Layer 2 — Detector Returning Zero Scanned Records

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🔴 **HIGH** | A detector that scans nothing is a blind spot, not a clean bill of health |
| **Detection Gap Risk** | High | Real unused tokens may exist and are not being evaluated |
| **Operational Risk** | High | False confidence in security posture |

**A detector reporting `scanned: 0` is not evidence of no problem — it is evidence of a broken detection pipeline.**

---

## 2. Possible Explanations Ranked by Likelihood

### Layer 1 — Why Was the Token Never Used?

| Rank | Explanation | Likelihood | Risk Level |
|---|---|---|---|
| 1 | **User abandoned session** (closed browser, got distracted, navigated away) | 🟢 High | Low |
| 2 | **Application/client-side error** prevented token from being attached to requests | 🟢 High | Low–Medium |
| 3 | **Automated health check or synthetic monitor** authenticated but wasn't designed to use the token | 🟡 Medium | Low |
| 4 | **Credential stuffing bot** authenticated successfully but the operator is validating credentials without needing to use the session (credential harvesting for later use or resale) | 🟡 Medium | **High** |
| 5 | **Token was intercepted in transit** (MitM, compromised endpoint) and the legitimate user never received it | 🟠 Low–Medium | **Critical** |
| 6 | **Attacker authenticated, received token, exfiltrated it out-of-band** (e.g., via a C2 channel), and will use it from a different host | 🟠 Low | **Critical** |
| 7 | **Insider threat** — authenticated to establish a token for later use or to test access before a planned action | 🔴 Low | **High** |
| 8 | **Race condition or clock skew** caused token to expire before first use | 🔴 Very Low | Low |

### Layer 2 — Why Did the Detector Scan Zero Records?

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | **Token store query returned empty** due to misconfigured filter, wrong table/index, or environment mismatch (e.g., scanning prod config against staging data) | High |
| 2 | **EventBridge Scheduler fired before token records were written** (race condition between token issuance and detector scan window) | High |
| 3 | **IAM/permissions issue** — Lambda or detector function lacks read access to the token store | Medium |
| 4 | **Token storage mechanism changed** (e.g., moved from DynamoDB to Redis) and detector was not updated | Medium |
| 5 | **Detector code bug** — query logic silently returns empty result set on error rather than raising an exception | Medium |
| 6 | **All tokens were recently purged/rotated** legitimately and the store is genuinely empty | Low |

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

#### For the Token Event Pattern:
```
[ ] 1. Identify the user account associated with the authentication event
[ ] 2. Pull the source IP address and run through threat intelligence feeds
        (VirusTotal, Shodan, AbuseIPDB, internal blocklists)
[ ] 3. Check if the IP is a known VPN exit node, Tor exit node, or datacenter IP
        (unexpected for a human user)
[ ] 4. Review authentication method — was MFA satisfied?
[ ] 5. Check for concurrent sessions from different IPs for the same user
[ ] 6. Review the user's authentication history for the past 30 days
        — is this login time/location consistent with baseline?
[ ] 7. Determine if this is a human user or service account
[ ] 8. Check whether the JWT was issued with elevated claims/scopes
```

#### For the Detector Gap:
```
[ ] 1. Manually query the token store to confirm whether tokens exist
[ ] 2. Check CloudWatch Logs for the detector Lambda execution
        — look for errors, timeouts, or empty query results
[ ] 3. Verify IAM role permissions for the detector function
[ ] 4. Confirm the detector is pointing to the correct data source
        (correct table, region, environment tag)
[ ] 5. Replay the EventBridge event manually and observe behavior
[ ] 6. Check if token storage backend was recently modified
```

### Short-Term (1–24 Hours)

```
[ ] 7.  If IP is suspicious: force token revocation and require re-authentication
[ ] 8.  If credential stuffing suspected: implement CAPTCHA or step-up auth
[ ] 9.  Correlate with failed login attempts preceding this success
        (success after failures = likely brute force or stuffing)
[ ] 10. Review WAF and rate-limiting logs for the authentication endpoint
[ ] 11
