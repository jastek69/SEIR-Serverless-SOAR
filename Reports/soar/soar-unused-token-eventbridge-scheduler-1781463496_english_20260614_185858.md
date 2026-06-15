# SOAR Report - unused-token-eventbridge-scheduler-1781463496 - 2026-06-14_18-58-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T18:58:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This means the security event description (user authenticated, JWT issued, token unused within 15 minutes) represents the *intended detection scenario* this system is designed to catch — but the detector itself may have a **visibility or pipeline gap** that prevented it from scanning any tokens at all. This meta-finding is arguably more significant than any individual unused token event and will be addressed throughout this analysis.

---

## 1. Severity Assessment

### Rating: **MEDIUM** (Individual Event) → **HIGH** (Detector Failure)

| Dimension | Rating | Justification |
|---|---|---|
| Individual unused token | LOW–MEDIUM | Alone, an unused token is a weak signal with many benign explanations |
| Detector returning `scanned: 0` | HIGH | A monitoring system that scans nothing provides false assurance |
| Blast radius if token is stolen | MEDIUM–HIGH | Depends on token scope, expiry, and signing algorithm |
| Detection gap risk | HIGH | Attackers who know monitoring is blind can operate freely |

### Justification

An unused JWT token is a **low-fidelity individual indicator** — users abandon sessions, close browsers, and experience network failures constantly. However, when correlated with other signals (credential stuffing, impossible travel, prior failed logins), it becomes a meaningful link in an attack chain.

The more pressing concern is the **detector health failure**. The `unused_token_detector` was invoked by EventBridge Scheduler but processed **zero records** (`scanned: 0`). This is not a clean bill of health — it is a **silent failure mode**. A functioning detector in a production environment with active users should virtually always scan at least some token records. The absence of scanned records suggests one or more of the following pipeline failures:

- The token store (Redis, DynamoDB, database) is unreachable or returning empty results
- The query logic has a bug (e.g., incorrect time window filter, wrong index)
- The EventBridge target invocation succeeded but the downstream Lambda/service failed silently
- Token issuance events are not being written to the store the detector queries

This creates a **detection blind spot** — the system believes it is monitoring for unused tokens but is effectively doing nothing.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused Token Event

| Rank | Explanation | Likelihood | Notes |
|---|---|---|---|
| 1 | User abandoned session (closed tab, navigated away) | Very High | Most common real-world cause |
| 2 | Client-side error prevented token use (CORS, network failure, JS error) | High | Common in SPAs and mobile apps |
| 3 | Automated health check or synthetic monitor authenticated but didn't proceed | High | CI/CD pipelines, uptime monitors |
| 4 | User authenticated on wrong environment (staging vs. prod) | Medium | Developer/QA error |
| 5 | Token issued to a bot/scraper that completed its objective without API calls | Medium | Some scrapers only need auth to validate credentials |
| 6 | **Credential validation attack** — attacker confirmed credentials are valid without triggering downstream alerts | Medium | Sophisticated attackers avoid using tokens to stay below detection thresholds |
| 7 | **Token harvesting** — attacker obtained the token via MITM or XSS and will use it later from a different host | Low–Medium | Explains why *this* client never used it |
| 8 | Race condition or clock skew caused token to expire before first use | Low | Possible in distributed systems with NTP drift |
| 9 | Insider threat probing authentication systems | Low | Warrants investigation if user is privileged |

### For the `scanned: 0` Detector Failure

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | Token store query returns empty due to misconfigured time window or index | High |
| 2 | Lambda/service cold start or timeout before completing scan | High |
| 3 | Token issuance not writing to the store the detector reads | Medium–High |
| 4 | Permissions issue — detector lacks read access to token store | Medium |
| 5 | Token store is empty because tokens are stateless (pure JWT, no server-side record) | Medium |
| 6 | EventBridge rule misconfigured — invokes detector but passes wrong parameters | Medium |
| 7 | Deliberate suppression by a threat actor with infrastructure access | Very Low |

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

**Step 1: Triage the Detector Health Issue First**

```
Priority: CRITICAL — A broken detector is a systemic risk, not a single-event risk.
```

- Verify the EventBridge Scheduler rule is correctly configured and the target (Lambda ARN, ECS task, etc.) is reachable
- Check CloudWatch Logs for the `unused_token_detector` Lambda/service execution — look for errors, timeouts, or empty result sets from the token store query
- Confirm the token store (Redis, DynamoDB, RDS) is accessible from the detector's execution context (VPC, security groups, IAM permissions)
- Manually run the detector query against the token store to confirm whether tokens exist

**Step 2: Investigate the Specific Authentication Event**

- Pull the full authentication log for the event:
  - Source IP, User-Agent, ASN, geolocation
  - Authentication method (password, SSO, MFA)
  - Account type (human user, service account, API key)
  - Prior authentication history for this account
- Check for preceding failed login attempts (credential stuffing indicator)
- Verify whether the source IP appears in threat intelligence feeds
- Check for concurrent sessions from different geolocations (impossible travel)

**Step 3: Assess Token Exposure Risk**

- Identify the JWT's claims: `sub`, `scope`, `roles`, `exp`, `aud`
- Determine if the token grants access to sensitive resources (admin APIs, PII, financial data)
- Check if the token has been seen in any downstream service logs (to confirm it truly was unused)
- If the token is still within its validity window and risk is elevated, consider revocation

### Short-Term (1–24 Hours)

- Audit all authentication events in the past 24 hours for the same source IP or user account
- Review token issuance pipeline to confirm tokens are being written to the store the detector queries
- Implement a detector health check: if `scanned == 0` and active users exist, fire a `DETECTOR_HEALTH_FAILURE` alert
- Cross-correlate with WAF logs, CDN logs, and application logs for the same session identifier

### Medium-Term (1–7 Days)

- Conduct a full audit of the `unused_token_detector` pipeline end-to-end
- Review token TTL policy — 15-minute unused threshold is reasonable, but ensure it aligns with your session architecture
- Establish a baseline of expected `scanned` counts per detector run to enable anomaly detection on the detector itself

---

## 4. Executive Summary

A security monitoring system designed to detect unused JWT tokens — a potential indicator of credential validation attacks, token harvesting, or abandoned sessions — was invoked by its scheduled trigger but **processed zero records**. This represents a **monitoring pipeline failure** that eliminates visibility into a meaningful authentication anomaly class.

The underlying detection scenario (a user authenticates, receives a JWT, and never uses it within the threshold window
