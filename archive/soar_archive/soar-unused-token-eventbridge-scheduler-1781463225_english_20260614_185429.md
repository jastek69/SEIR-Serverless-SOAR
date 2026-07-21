# SOAR Report - unused-token-eventbridge-scheduler-1781463225 - 2026-06-14_18-53-45_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T18:53:45Z
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

### Threat Scenario Severity (If Findings Were Present)
| Dimension | Rating | Justification |
|---|---|---|
| **Inherent Threat Severity** | **Medium (3/5)** | Unused tokens alone are a weak signal, but in aggregate or with correlated events, they indicate credential harvesting, automated probing, or session pre-staging |
| **Confidentiality Impact** | Medium | Issued JWT may encode sensitive claims (roles, PII, internal resource identifiers) |
| **Integrity Impact** | Low-Medium | Token not yet used; no confirmed unauthorized action |
| **Availability Impact** | Low | No service disruption indicated |
| **Detection Confidence** | Low-Medium | Single behavioral indicator without corroboration |

### Detector Health Severity (Current Execution)
| Dimension | Rating | Justification |
|---|---|---|
| **Operational Risk** | **High (4/5)** | `scanned: 0` means the detector is running blind — it is producing false assurance |
| **Detection Gap** | Critical | If tokens exist in the data store and are not being scanned, the entire detection capability is silently failing |
| **Blast Radius** | High | Every unused-token threat scenario goes undetected during this failure window |

> **Key Finding:** The most urgent risk is not the unused token threat itself — it is that the detector responsible for catching it is currently non-functional. A silent failure in a security control is categorically more dangerous than the threat it was designed to detect, because it creates a false sense of coverage.

---

## 2. Possible Explanations Ranked by Likelihood

### Dimension A: Why a Token Might Be Issued But Never Used

#### 1. ✅ Benign User Abandonment (Likelihood: High — ~45%)
**Explanation:** User authenticated (e.g., clicked a login link, initiated SSO flow) but abandoned the session before completing any action — closed the browser tab, got distracted, or experienced a UI error post-login.

**Supporting indicators:**
- No preceding failed authentication attempts
- Single authentication event with no follow-on API calls
- User-agent consistent with browser-based access

**Risk level:** Low. No malicious intent, but token remains valid and represents an orphaned credential.

---

#### 2. ✅ Automated Script / Bot Authentication Probe (Likelihood: Medium-High — ~25%)
**Explanation:** An automated actor (credential stuffing tool, reconnaissance bot) successfully authenticated using valid credentials — possibly obtained via phishing, breach data, or password spraying — but did not proceed to use the token, either because:
- The script failed after authentication
- The actor was testing credential validity without intending immediate exploitation
- The token was harvested for later use (token exfiltration)

**Supporting indicators:**
- Authentication from unusual IP, ASN, or geolocation
- Non-standard user-agent string
- Authentication at unusual hours
- Absence of preceding failed attempts (suggests valid credential, not brute force)

**Attack path:**
```
Credential Stuffing DB → Valid Creds Found → Auth Endpoint Hit →
JWT Issued → Token Exfiltrated to C2 → Delayed Exploitation
```

**Risk level:** High. If this is the scenario, the token is a live credential in adversary hands.

---

#### 3. ✅ Integration / Service Account Misconfiguration (Likelihood: Medium — ~15%)
**Explanation:** A service account or API integration authenticated successfully but failed to proceed due to a misconfiguration, network error, or downstream service failure. The token was issued but the consuming service never made an API call.

**Supporting indicators:**
- Authentication from a static IP (server/cloud provider range)
- Service account username pattern
- Correlated infrastructure errors in application logs
- Repeated pattern across multiple time windows

**Risk level:** Low-Medium. Not malicious, but indicates a broken integration that may be retrying and generating unnecessary token churn.

---

#### 4. ⚠️ Token Exfiltration via XSS or Client-Side Attack (Likelihood: Low-Medium — ~10%)
**Explanation:** User authenticated legitimately; token was issued to the browser but was immediately exfiltrated via an XSS payload before the user could make any authenticated request. The legitimate user session then appeared "unused" because the token was stolen before use.

**Attack path:**
```
User visits malicious/compromised page →
XSS payload fires on auth callback →
JWT extracted from localStorage/cookie →
Token POSTed to attacker-controlled endpoint →
Legitimate session appears idle
```

**Supporting indicators:**
- User had recently visited external or user-generated content pages
- CSP violations logged around the same time
- Token appears in outbound network logs to unexpected domains

**Risk level:** High. Token is in adversary hands with full user privileges.

---

#### 5. ⚠️ Insider Threat / Credential Sharing (Likelihood: Low — ~5%)
**Explanation:** A user authenticated and shared or forwarded the token to an unauthorized party. The original session was abandoned while the token was used elsewhere (though "never used" suggests this is less likely unless the secondary use is also being tracked separately).

**Risk level:** Medium-High depending on user privilege level.

---

### Dimension B: Why the Detector Returned Zero Scanned Records

#### 1. ✅ Data Source Connection Failure (Likelihood: High — ~40%)
The detector could not connect to the token store (Redis, DynamoDB, RDS, etc.) — connection timeout, IAM permission error, or endpoint misconfiguration.

#### 2. ✅ Empty Token Store / No Active Sessions (Likelihood: Medium — ~30%)
The system genuinely has no active tokens at scan time — possible in low-traffic environments, after a deployment that flushed sessions, or during off-hours.

#### 3. ✅ Query/Filter Logic Bug (Likelihood: Medium — ~20%)
The detector's query is filtering incorrectly (e.g., wrong time window comparison, timezone mismatch, wrong index) and returning zero results even when records exist.

#### 4. ⚠️ Detector Deployment/Configuration Error (Likelihood: Low-Medium — ~10%)
The Lambda function, container, or script is misconfigured — wrong environment variables, wrong region, wrong table/index name.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Validate Detector Operational Status
├── Confirm whether token store contains active records
├── Manually query token store for records in last 60 minutes
├── Check detector execution logs (CloudWatch, Splunk, etc.)
├── Verify IAM permissions for detector's execution role
└── Confirm EventBridge Scheduler fired correctly and on schedule

Priority 2: If Detector Failure Confirmed
├── Escalate as a detection gap / control failure
├── Initiate manual token audit for the gap window
└── Document time window of blind coverage
```

### Short-Term Actions (1–24 Hours)

```
Priority 3: Threat Hunt for the Intended
