# SOAR Report - unused-token-unused-token-detector-1781382194 - 2026-06-13_20-23-14_UTC

- Trigger: unused-token-detector
- Generated: 2026-06-13T20:23:14Z
- Threshold Minutes: 5
- Records Scanned: 0
- Alerts Published: 0
- Reason: Unused token threshold scan
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
**CVSS Qualitative Range: 3.1–5.4 (Low to Medium)**

### Justification

In isolation, a single unused JWT token is a weak signal. However, the pattern warrants structured analysis because it sits at the intersection of **credential issuance and behavioral anomaly detection** — a space frequently exploited in modern attack chains.

| Factor | Assessment |
|---|---|
| Confidentiality Impact | Low — no data access confirmed |
| Integrity Impact | None observed |
| Availability Impact | None |
| Authentication Bypass | Not confirmed, but possible precursor |
| Lateral Movement Risk | Low at this stage |
| Correlation Potential | Medium — valuable when aggregated |

**Key Severity Driver:** The event itself is not inherently dangerous. The danger lies in what it *may represent* — a reconnaissance probe, a credential stuffing hit, an automated token harvester, or a broken legitimate workflow. The severity escalates significantly if correlated with:

- Multiple accounts exhibiting the same pattern
- Authentication from unusual geolocations or ASNs
- Prior failed authentication attempts on the same account
- Token issuance volume spikes

> ⚠️ **Critical Context Note:** The provided JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector **ran but produced no findings**. This is itself a signal worth investigating — either the system is functioning correctly with no anomalies, or the detector has a **coverage gap, misconfiguration, or data pipeline failure**.

---

## 2. Possible Explanations Ranked by Likelihood

### Rank 1 — Legitimate User Abandonment (Most Likely, ~45%)

**Description:** A real user authenticated, received a token, and then abandoned the session before performing any action. Common causes include:

- Distraction immediately after login
- Slow application load causing user to close the tab
- Mobile app backgrounded before first API call
- User authenticated to check something, then decided not to proceed

**Indicators Supporting This:**
- Single occurrence on a known account
- Authentication from a known IP/device fingerprint
- Normal business hours timing
- No prior failed attempts

**Risk Level:** Negligible in isolation

---

### Rank 2 — Automated Script or Bot Probe (Likely, ~25%)

**Description:** An automated system authenticated successfully (possibly via credential stuffing or a compromised API key) and issued a token but did not proceed — potentially because:

- The bot was testing credential validity without needing to use the token
- The automation pipeline failed after authentication
- The attacker was enumerating valid accounts before a second-stage attack

**Indicators Supporting This:**
- Authentication at unusual hours
- User-agent string anomalies
- IP associated with VPN, Tor, or datacenter ASN
- Multiple accounts showing the same pattern in a short window
- Authentication latency unusually low (sub-second form completion)

**Risk Level:** Medium — valid credential confirmation is a meaningful attacker milestone

**Attack Path:**
```
[Credential Stuffing List] 
        ↓
[Automated Auth Attempt] 
        ↓
[Successful Login + JWT Issued] ← YOU ARE HERE
        ↓
[Token Stored / Account Flagged as Valid]
        ↓
[Second-Stage Attack: Data Exfiltration, Account Takeover, Privilege Escalation]
```

---

### Rank 3 — Broken Application Workflow (Likely, ~20%)

**Description:** A legitimate integration, CI/CD pipeline, microservice, or scheduled job authenticated but failed to proceed due to:

- Application bug causing token to be dropped
- Network timeout between auth service and consuming service
- Misconfigured service account
- Token not being passed correctly in subsequent requests

**Indicators Supporting This:**
- Service account or non-human identity involved
- Consistent pattern at scheduled intervals
- Error logs in adjacent systems at the same timestamp
- Same service account repeatedly triggering the pattern

**Risk Level:** Low from a security perspective, but indicates operational reliability issues

---

### Rank 4 — Reconnaissance / Account Enumeration (~7%)

**Description:** An attacker is systematically validating which accounts exist and have active credentials. The token is a side effect of successful authentication — the attacker's goal was simply the HTTP 200 response.

**Attack Path:**
```
[Username/Password List]
        ↓
[Auth Endpoint Probing]
        ↓
[200 OK + JWT = Valid Account Confirmed] ← YOU ARE HERE
        ↓
[Account List Sold / Used for Targeted Phishing / MFA Fatigue Attack]
```

**Risk Level:** Medium — the blast radius extends beyond the individual account

---

### Rank 5 — Insider Threat or Shared Credential Testing (~3%)

**Description:** An insider or someone with legitimate access is testing whether credentials still work — possibly before sharing them externally, or verifying access before a planned malicious action.

**Risk Level:** High if confirmed, but low prior probability without additional signals

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
[ ] 1. Investigate the detector anomaly
        - Why does the scan show scanned: 0 and findings_total: 0?
        - Verify the detector is ingesting authentication logs correctly
        - Check for pipeline failures, misconfigured log sources, or 
          broken queries in the SIEM/detection platform
        - Confirm the threshold_minutes: 5 is correctly applied

[ ] 2. Pull the raw authentication event
        - Source IP address and ASN lookup
        - Geolocation — does it match user's known locations?
        - User-agent string analysis
        - Device fingerprint comparison against historical logins
        - Time of authentication — business hours or anomalous?

[ ] 3. Check for failed authentication attempts
        - Were there failed attempts before this success?
        - Is this account in any known breach datasets?
        - Run the source IP against threat intelligence feeds 
          (VirusTotal, AbuseIPDB, Shodan)
```

### Short-Term Actions (1–24 Hours)

```
[ ] 4. Broaden the query — look for the pattern at scale
        - How many accounts showed unused tokens in the same window?
        - Is there a spike in authentication volume without 
          corresponding API activity?
        - Cluster by source IP to detect coordinated activity

[ ] 5. Review token issuance logs
        - Was the token a standard access token or a refresh token?
        - Was the token's expiry set correctly?
        - Was the token ever transmitted to a third-party service?

[ ] 6. Contact the user (if human account)
        - Soft verification: "Did you log in at [time] from [location]?"
        - Do not reveal investigation details
        - Assess response for social engineering indicators

[ ] 7. Validate detector health
        - Run a synthetic test: manually create an unused token scenario
          and confirm the detector fires correctly
        - Review detector logic for edge cases (clock skew, timezone 
          issues, token format variations)
```

### Escalation Triggers

Escalate to **MEDIUM** or **HIGH** if any of the following are true:

- Source IP matches known threat actor infrastructure
- Same pattern observed across 5+ accounts
- Account belongs to a privileged user (admin, finance, executive)
- Authentication occurred from a country the user has never accessed from
- Token was issued but the user reports they did not authenticate
