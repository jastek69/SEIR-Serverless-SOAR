# SOAR Report - unused-token-eventbridge-scheduler-1781382542 - 2026-06-13_20-29-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:29:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This materially shapes the analysis. The narrative event description (token issued, never used within 15 minutes) represents the *intended detection scenario* this system is designed to catch, but the current execution produced no data. Both dimensions — the threat model the detector addresses and the operational health of the detector itself — require analysis.

---

## 1. Severity Assessment

### Primary Threat Scenario (What the Detector Is Designed to Catch)

| Dimension | Rating | Justification |
|---|---|---|
| **Inherent Threat Severity** | **Medium (3/5)** | Unused tokens alone are weak signals; context determines escalation |
| **Detection Gap Risk** | **High (4/5)** | If detector is malfunctioning, an entire attack class goes unmonitored |
| **Operational Risk (Current Run)** | **High (4/5)** | Zero scanned records is anomalous and suggests pipeline failure |
| **Composite Risk** | **High** | Detector health failure elevates overall risk posture |

### Justification

An authenticated session that produces a JWT but never exercises it sits at an interesting intersection of **low-signal, high-context** security events. In isolation, it is benign — users abandon sessions, close browsers, or experience network interruptions constantly. However, at scale or in combination with other indicators, it becomes a meaningful signal for:

- **Credential stuffing validation runs** — attackers authenticate to confirm credential validity without triggering downstream activity-based detections
- **Token harvesting** — a compromised authentication flow where the token is exfiltrated before use
- **Automated reconnaissance** — bots probing authentication endpoints to map valid accounts

The **threshold_minutes: 5** (tighter than the 15-minute narrative) suggests the engineering team has already tuned this detector toward catching short-window abuse, which is appropriate for credential stuffing patterns.

The **scanned: 0** finding is the more urgent concern. A scheduled detector that processes no records either means there are genuinely no tokens to evaluate (plausible in low-traffic environments) or the data pipeline feeding the detector is broken — which means real malicious unused tokens would be silently missed.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Zero-Scan Detector State

| Rank | Explanation | Likelihood | Evidence Basis |
|---|---|---|---|
| 1 | **No tokens exist in the evaluation window** | High | Low-traffic environment, off-hours scheduler run, or all tokens were used/expired before scan |
| 2 | **Data source query returned empty due to misconfiguration** | Medium-High | Incorrect time window filter, wrong table/index, or IAM permission regression |
| 3 | **Token store is unavailable or unreachable** | Medium | Database connection failure, Redis cache down, or network partition |
| 4 | **Scheduler fired before token ingestion pipeline completed** | Medium | Race condition between token write and detector read |
| 5 | **Detector code bug introduced by recent deployment** | Low-Medium | Logic error in scan query silently returns empty set |
| 6 | **Intentional suppression by an insider or attacker** | Low | Requires elevated access; worth ruling out if other anomalies exist |

### For the Threat Scenario (Token Issued, Never Used)

| Rank | Explanation | Likelihood | Evidence Basis |
|---|---|---|---|
| 1 | **Benign user abandonment** | Very High | User authenticated, was interrupted, closed tab, or lost connectivity |
| 2 | **Automated health check / synthetic monitoring** | High | CI/CD pipelines, uptime monitors, and load balancers often authenticate without consuming tokens |
| 3 | **Credential stuffing — validity check only** | Medium | Attacker confirms credential works; no need to use the token if goal is enumeration |
| 4 | **Token exfiltration before use** | Low-Medium | MITM or compromised client intercepts token; attacker uses it from different infrastructure |
| 5 | **Authentication flow testing by developer** | Low-Medium | Developer testing login flow in production without completing a workflow |
| 6 | **Broken client application** | Low | Client receives token but fails to store or transmit it correctly |
| 7 | **Account takeover probe** | Low | Attacker testing stolen credentials before launching a larger campaign |

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

#### Step 1: Validate Detector Health
This is the highest priority action given `scanned: 0`.

```
□ Verify the token store (DB/cache) is reachable from the Lambda/service running the detector
□ Manually execute the detector's underlying query against the token store
□ Check CloudWatch Logs for the detector's Lambda execution — look for exceptions, timeouts, or empty query results
□ Verify IAM role permissions haven't changed (GetItem, Query, Scan on the token table)
□ Confirm EventBridge Scheduler fired at the correct time and the invocation was not throttled
□ Check if a recent deployment changed the token schema, table name, or index structure
```

#### Step 2: Cross-Reference Authentication Logs
If the detector is healthy and `scanned: 0` is legitimate:

```
□ Query your IdP/auth service logs for all successful authentications in the past 60 minutes
□ Identify any tokens issued but with no corresponding downstream API calls
□ Correlate source IPs against threat intelligence feeds
□ Check for authentication velocity anomalies (same IP authenticating multiple accounts)
```

#### Step 3: Establish Baseline
```
□ Determine the normal rate of "unused token" events in your environment
□ If this is a new detector, establish Day 1 baseline before tuning thresholds
□ Document expected zero-scan scenarios (maintenance windows, off-hours, etc.)
```

### Short-Term (1–24 Hours)

```
□ Add explicit alerting when scanned: 0 occurs outside of known maintenance windows
□ Implement a canary token — a synthetic token that should always appear in the scan — to validate detector liveness
□ Review authentication logs for the past 7 days for patterns of unused tokens
□ If credential stuffing is suspected, cross-reference with WAF logs for authentication endpoint abuse
□ Verify token revocation is functioning — unused tokens should be invalidated after threshold_minutes
```

### Investigation Queries (Pseudo-SQL / CloudWatch Insights)

```sql
-- Find all tokens issued but never used in the last 24 hours
SELECT 
    user_id,
    token_id,
    issued_at,
    source_ip,
    user_agent,
    COUNT(*) as unused_token_count
FROM auth_events
WHERE 
    event_type = 'TOKEN_ISSUED'
    AND token_id NOT IN (
        SELECT DISTINCT token_id 
        FROM api_access_logs 
        WHERE timestamp > NOW() - INTERVAL 24 HOURS
    )
    AND issued_at > NOW() - INTERVAL 24 HOURS
GROUP BY user_id, token_id, issued_at, source_ip, user_agent
ORDER BY unused_token_count DESC;
```

```sql
-- Detect credential stuffing pattern: many users, same IP, unused tokens
SELECT 
    source_ip,
    COUNT(DISTINCT user_id) as
