# SOAR Report - unused-token-manual-1781465276 - 2026-06-14_19-27-56_UTC

- Trigger: manual
- Generated: 2026-06-14T19:27:56Z
- Threshold Minutes: 5
- Records Scanned: 0
- Alerts Published: 0
- Reason: Operator-requested unused token review
- Prompt Source: ssm
- Prompt Parameter: /bedrock/soar-prompt
- Bedrock Model: us.anthropic.claude-sonnet-4-6

## Stale Tokens
- No stale unused tokens matched the threshold during this run.

## SOAR Analysis
# Security Event Analysis: Unused JWT Token Post-Authentication

---

## 1. Severity Assessment

**Severity: LOW–MEDIUM (Contextual)**
**Confidence: MODERATE** *(limited signal due to zero findings in scan context)*

### Justification

On the surface, a successful authentication followed by an unused JWT token appears benign — users abandon sessions, close browsers, or experience connectivity issues routinely. However, this pattern becomes analytically significant under specific conditions:

| Factor | Risk Contribution |
|---|---|
| Token issued but never used | Potential credential harvesting without exploitation |
| 15-minute window (above 5-min threshold) | Suggests deliberate or automated issuance |
| Zero findings in detector scan | Detector may have gaps; manual trigger warrants scrutiny |
| Manual trigger by operator | Implies pre-existing suspicion or routine audit |

> **Critical nuance:** The event context JSON reveals `scanned: 0` and `findings_total: 0`. This is not a clean bill of health — it indicates the detector **did not scan any tokens**, which is itself an anomaly. A detector that runs but processes zero records suggests a **pipeline failure, misconfiguration, or data ingestion gap**, not an absence of risk.

The severity escalates from LOW to MEDIUM specifically because:
- The detection infrastructure appears non-functional during this review cycle
- An operator felt compelled to manually trigger the review, implying prior concern
- Blind spots in token monitoring create exploitable detection gaps

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Benign User Abandonment *(~45% probability)*
The user authenticated, received a token, and then:
- Closed the browser tab before completing an action
- Lost network connectivity
- Was interrupted and did not return within the window
- Experienced a client-side application crash

**Why it matters despite being benign:** Even legitimate abandonment at scale creates a pool of valid, unmonitored tokens that represent an attack surface if intercepted.

---

### Rank 2 — Detector/Pipeline Failure *(~30% probability)*
The `scanned: 0` field is the most operationally significant data point in this event. Possible causes:
- Token store query returning empty due to a schema change or index failure
- Time-window filter misconfigured (e.g., UTC offset error causing no records to fall within range)
- Message queue or log pipeline backlog causing delayed ingestion
- The detector job itself failing silently and reporting success with empty results

**Attack path implication:** If the detector is broken, adversaries who have obtained tokens via phishing, MITM, or credential stuffing can hold tokens without triggering any alerts — indefinitely, until the token expires.

---

### Rank 3 — Credential Harvesting / Token Theft Probe *(~15% probability)*
An attacker may authenticate using stolen or brute-forced credentials to:
- Validate that credentials are active without triggering use-based detection
- Harvest a valid JWT for later use (outside the monitoring window)
- Test authentication endpoints as part of reconnaissance
- Automate credential validation at scale (credential stuffing validation phase)

**Attack path detail:**
```
Attacker obtains credential list
        ↓
Authenticates against /auth endpoint
        ↓
JWT issued and captured (e.g., via intercepting proxy)
        ↓
Token stored for later use or sold
        ↓
No downstream API calls → evades behavioral detection
        ↓
Token used hours/days later from different IP/device
```

This pattern is specifically designed to evade "impossible travel" and "anomalous API usage" detectors by decoupling the authentication event from the exploitation event.

---

### Rank 4 — Automated Testing or CI/CD Pipeline *(~7% probability)*
- Integration tests that authenticate but do not complete full user flows
- Load testing tools generating auth tokens without subsequent API calls
- Misconfigured service accounts in staging/production overlap scenarios

---

### Rank 5 — Insider Threat or Privilege Enumeration *(~3% probability)*
An insider or compromised internal account authenticating to:
- Confirm access still exists before a planned malicious action
- Test whether their account has been flagged or restricted
- Generate tokens for exfiltration to an external party

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

**Step 1: Diagnose the Detector Failure**
The `scanned: 0` result must be treated as a P1 operational issue. Before any threat hunting, restore visibility:

```bash
# Check detector job logs
grep -i "unused_token_detector" /var/log/security/detector.log | tail -100

# Verify token store connectivity
curl -X GET https://internal-token-store/health

# Check time window alignment
date -u  # Confirm UTC alignment with detector config
```

**Step 2: Manually Query Token Store**
Bypass the broken detector and query directly:

```sql
-- Direct query to identify unused tokens in the last 24 hours
SELECT
    token_id,
    user_id,
    issued_at,
    last_used_at,
    ip_address,
    user_agent,
    expiry
FROM jwt_tokens
WHERE
    issued_at >= NOW() - INTERVAL '24 HOURS'
    AND (last_used_at IS NULL OR last_used_at = issued_at)
    AND expiry > NOW()
ORDER BY issued_at DESC;
```

**Step 3: Correlate Authentication Events**
For any tokens surfaced in Step 2, cross-reference:
- Source IP against threat intelligence feeds (VirusTotal, AbuseIPDB, internal blocklists)
- User agent strings for anomalies (headless browsers, known scanning tools)
- Geographic location against user's historical login patterns
- Authentication time against user's typical activity hours

---

### Short-Term (1–24 Hours)

**Step 4: Review Authentication Logs for the Specific Event**
```bash
# Extract auth events with no subsequent API calls within 15 minutes
# Assumes structured logging to SIEM
index=auth_events sourcetype=jwt_issuance
| join token_id [search index=api_events]
| where isnull(api_call_time) OR (api_call_time - issued_at) > 900
| table user_id, token_id, issued_at, source_ip, user_agent
```

**Step 5: Enrich the Specific User/Session**
- Pull full authentication history for the user in question
- Check for concurrent sessions from different IPs
- Review any password reset or MFA events in the preceding 48 hours
- Verify whether the user's credentials appear in breach databases (HaveIBeenPwned API, internal dark web monitoring)

**Step 6: Assess Token Exposure Window**
Determine the token's remaining validity and decide whether to preemptively revoke:

```python
import jwt
from datetime import datetime

def assess_token_risk(token_string, secret_key):
    decoded = jwt.decode(token_string, secret_key, algorithms=["HS256"])
    issued_at = datetime.fromtimestamp(decoded['iat'])
    expiry = datetime.fromtimestamp(decoded['exp'])
    time_remaining = expiry - datetime.utcnow()
    
    risk_factors = {
        "time_remaining_minutes": time_remaining.seconds // 60,
        "issued_at": issued_at.isoformat(),
        "expiry": expiry.isoformat(),
        "subject": decoded.get('sub
