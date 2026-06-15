# SOAR Report - unused-token-eventbridge-scheduler-1781467396 - 2026-06-14_20-03-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T20:03:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This is itself a significant signal — not of a confirmed threat, but of a potential **detection gap or pipeline failure**. The analysis below addresses both the theoretical security event described in the prompt *and* the operational anomaly embedded in the JSON context.

---

## 1. Severity Assessment

### Primary Event (Unused Token Post-Authentication)
| Dimension | Rating | Justification |
|---|---|---|
| **Inherent Risk** | Medium (3/5) | Unused tokens alone are not malicious, but the pattern is a recognized precursor to credential harvesting and session staging |
| **Contextual Risk** | Low-Medium | No corroborating indicators (no lateral movement, no token replay, no anomalous source IP) present in findings |
| **Detection Confidence** | **Low** | The detector scanned 0 records — the absence of findings may reflect a broken pipeline, not a clean environment |
| **Blast Radius** | Medium-High | If the token was issued with broad scopes/claims and is later replayed, the impact could be significant depending on the service |

### Secondary Event (Detector Anomaly)
| Dimension | Rating | Justification |
|---|---|---|
| **Operational Severity** | **High** | A detector that scans 0 records when it should be scanning active token issuance events represents a blind spot in your detection coverage |
| **Risk of False Confidence** | Critical | Teams may assume the environment is clean when the detector is simply not functioning |

> **Overall Severity: MEDIUM with a HIGH-priority operational finding requiring immediate investigation of the detection pipeline.**

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused Token Pattern

#### Rank 1 — Benign User Behavior (Most Likely, ~55%)
**Description:** The user authenticated, received a token, and then abandoned the session — browser tab closed, network interruption, distraction, or the application crashed before the token could be used.

**Supporting Evidence:**
- Single isolated event with no corroborating anomalies
- No token replay detected
- Common in web applications where authentication flows are initiated but not completed

**Risk Trade-off:** While individually benign, at scale this pattern can mask malicious activity if not baselined properly.

---

#### Rank 2 — Automated Credential Validation / Credential Stuffing (Likely, ~25%)
**Description:** An adversary is testing harvested credentials to validate which accounts are active without triggering downstream application behavior. The authentication succeeds (confirming the credential is valid), but the token is never used because the attacker's goal was only validation — not session exploitation.

**Attack Path:**
```
Harvested Credential List
        │
        ▼
Automated Auth Request ──► Authentication Success ──► JWT Issued
        │
        ▼
Token Discarded (attacker logs "credential valid")
        │
        ▼
Credential sold / used later in targeted attack
```

**Why This Is Dangerous:**
- The attacker gains confirmed valid credentials without triggering application-layer anomalies
- The JWT is never replayed, so token-abuse detectors produce no signal
- The account may be targeted days or weeks later, breaking temporal correlation

**Blast Radius:** If credentials are confirmed valid and later used in a targeted attack, the blast radius depends entirely on the account's privilege level and the application's authorization model.

---

#### Rank 3 — Token Harvesting / Session Staging (~10%)
**Description:** A malicious actor or compromised client authenticated and received a token but is holding it for later use — potentially waiting for a monitoring quiet window (e.g., nights, weekends) or staging for a coordinated attack.

**Attack Path:**
```
Attacker authenticates ──► JWT issued with full claims/scopes
        │
        ▼
Token stored in attacker-controlled infrastructure
        │
        ▼
Token replayed later (potentially outside detection window)
        │
        ▼
Unauthorized resource access, data exfiltration, privilege escalation
```

**Detection Gap:** If your token expiry is long (e.g., 24 hours or more), the token remains valid and exploitable well beyond the 15-minute observation window.

---

#### Rank 4 — Misconfigured Application / Integration (~7%)
**Description:** A service account, CI/CD pipeline, or third-party integration authenticated successfully but failed to use the token due to a misconfiguration, deployment error, or dependency failure.

**Indicators to Look For:**
- Service account or non-human identity as the subject
- Repeated pattern at regular intervals (suggesting automated retry)
- Correlation with deployment events or configuration changes

---

#### Rank 5 — Insider Threat / Reconnaissance (~3%)
**Description:** A legitimate user authenticated to confirm their access still works — potentially before exfiltrating data or performing unauthorized actions — but did not proceed in this session.

---

### For the Detector Anomaly (Zero Scans)

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | **No token issuance events in the scan window** — EventBridge fired but the token store/log source had no records to evaluate | ~40% |
| 2 | **Data pipeline failure** — Events not reaching the detector (Kinesis lag, SQS queue failure, log ingestion gap) | ~30% |
| 3 | **Query/filter misconfiguration** — The detector's query is too narrow and filtering out valid records | ~20% |
| 4 | **Intentional suppression / adversarial log tampering** — Unlikely but must be considered in high-threat environments | ~10% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### Step 1: Validate the Detection Pipeline
This is the **highest priority action** given the zero-scan result.

```
□ Verify EventBridge Scheduler fired at the correct time
□ Confirm the Lambda/function invoked by EventBridge executed successfully
□ Check CloudWatch Logs for the unused_token_detector function:
    - Were there execution errors?
    - Did the function connect to the data source?
    - Was the scan window correctly calculated?
□ Validate the data source (DynamoDB, Redis, RDS, etc.) contains token records
□ Manually query the token store for tokens issued in the last 15–30 minutes
□ Confirm IAM permissions for the detector function are intact
```

#### Step 2: Identify the Specific Authentication Event
```
□ Pull the authentication log for the specific user/session
□ Extract:
    - Source IP address
    - User-Agent string
    - Geographic location
    - Authentication method (password, MFA, SSO, API key)
    - Timestamp precision
    - JWT claims (sub, aud, scope, exp, iat)
□ Check if MFA was required and completed
□ Verify if this is a human identity or service account
```

#### Step 3: Correlate Across Log Sources
```
□ Search for the source IP across all log sources in the past 30 days
□ Check for other authentication attempts from the same IP (success and failure)
□ Look for the same user authenticating from multiple IPs simultaneously
□ Query threat intelligence feeds for the source IP
□ Check if the user has any other active sessions
```

### Short-Term Actions (1–24 Hours)

```
□ Review
