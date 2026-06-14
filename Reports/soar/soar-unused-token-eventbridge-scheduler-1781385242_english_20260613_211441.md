# SOAR Report - unused-token-eventbridge-scheduler-1781385242 - 2026-06-13_21-14-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T21:14:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the provided JSON context.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and an empty `findings_sample`. This means the detector ran but found **nothing to analyze** — no tokens were scanned at all.

This discrepancy is itself a security-relevant finding and will be treated as a primary concern throughout this analysis. Both the hypothetical scenario (had tokens been found) and the actual detector failure are addressed below.

---

## 1. Severity Assessment

### Actual Event (Detector Produced No Scan Results)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟡 **MEDIUM** | A detection control silently produced zero results, creating a blind spot |
| **Confidentiality Impact** | Low-Medium | Unknown — the detector may be missing real events |
| **Integrity Impact** | Medium | Detection pipeline integrity is compromised |
| **Availability Impact** | Low | No service disruption observed |
| **Detection Gap Risk** | **HIGH** | If tokens exist but aren't being scanned, the control is ineffective |

### Hypothetical Event (Had Unused Tokens Been Found)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟠 **MEDIUM-HIGH** | Depends heavily on token privilege level and volume |
| **Confidentiality Impact** | Medium-High | Issued tokens represent valid credential material |
| **Integrity Impact** | Medium | Potential for unauthorized session establishment |

### Severity Justification — The Real Finding

The `scanned: 0` result from `unused_token_detector` is the most operationally significant element of this event. A detector that runs but scans zero records can mean:

- The token store/database query returned no rows (pipeline misconfiguration)
- The EventBridge Scheduler invoked the wrong Lambda version or ARN
- The detector's data source (e.g., Redis, DynamoDB, RDS) is unreachable or empty
- A code regression silently short-circuits the scan loop
- The threshold filter (`threshold_minutes: 5`) is misconfigured and excludes all records

**A silent, non-alerting detector is operationally equivalent to no detector.** This is a control failure, not a clean bill of health.

---

## 2. Possible Explanations Ranked by Likelihood

### Scenario A: Detector Misconfiguration or Code Defect *(Likelihood: HIGH — ~55%)*

The most probable explanation. The detector ran successfully from an infrastructure perspective (EventBridge triggered it, it completed without error) but the internal logic produced no scan results.

**Attack Path / Failure Path:**
```
EventBridge Scheduler fires
    → Lambda invoked successfully
        → Token store query executes
            → Query returns 0 rows (filter bug, wrong table, empty TTL window)
                → findings_total = 0, scanned = 0
                    → Alert never fires
                        → Real unused tokens go undetected indefinitely
```

**Evidence supporting this:**
- `threshold_minutes: 5` in the detector config vs. `15 minutes` in the event description — a mismatch suggesting the detector may be filtering with the wrong window
- `scanned: 0` is abnormal unless the system genuinely has zero authenticated users in the scan window, which is unlikely in production
- No error state is reported, suggesting the code completed normally but with an empty dataset

---

### Scenario B: Token Store Is Empty or Unreachable *(Likelihood: MEDIUM — ~25%)*

The underlying data source (Redis cache, DynamoDB table, or relational DB) holding issued-but-unused tokens may be:

- Misconfigured (wrong endpoint, wrong table name, wrong Redis keyspace)
- Experiencing a silent connection failure that returns empty results rather than an exception
- Correctly empty because tokens are stored elsewhere or TTL expiry already removed them before the scan ran

**Risk implication:** If tokens are evicted from the store before the detector runs, the detection window is effectively zero. An attacker who obtains a token and uses it just before TTL expiry would never be flagged.

---

### Scenario C: Legitimate System State — No Active Sessions *(Likelihood: LOW-MEDIUM — ~15%)*

In low-traffic environments (dev/staging, off-hours production), it is conceivable that no users authenticated within the scan window. However:

- This should still produce `scanned > 0` if the query correctly examines the full token issuance log
- A `scanned: 0` result is only truly benign if the system can affirmatively confirm zero tokens were issued in the window

---

### Scenario D: Adversarial Suppression of Detection *(Likelihood: LOW — ~5%)*

A sophisticated attacker with access to the detection pipeline could suppress results by:

- Modifying the Lambda function code or environment variables
- Altering EventBridge scheduler targets to invoke a neutered version
- Manipulating the token store to remove evidence of issued tokens
- Exploiting IAM misconfiguration to disable the detector role

**This is low probability but high impact.** If an attacker has already compromised the environment sufficiently to suppress detection, the blast radius extends to all authenticated sessions.

---

### Hypothetical Scenario E: Genuine Unused Token Anomaly *(If tokens had been found)*

Had the detector returned findings, the ranked explanations would be:

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | User authenticated then abandoned session (browser close, network drop) | ~40% |
| 2 | Automated script/bot authentication without follow-through | ~25% |
| 3 | Credential stuffing — attacker validated credentials but didn't proceed (avoiding detection) | ~20% |
| 4 | Token harvesting — attacker obtained token for later use outside the monitored window | ~10% |
| 5 | Service account misconfiguration | ~5% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–2 Hours)

```
Priority 1: Validate detector operational status
├── Confirm EventBridge Scheduler invocation logs in CloudWatch
├── Review Lambda execution logs for the unused_token_detector function
├── Verify the Lambda completed successfully (exit code, duration, memory)
└── Check for silent exceptions swallowed by try/catch blocks

Priority 2: Validate data source connectivity
├── Confirm the token store (Redis/DynamoDB/RDS) is reachable from the Lambda VPC
├── Run a manual query against the token store to check record count
├── Verify IAM permissions allow the Lambda role to read from the token store
└── Check for recent infrastructure changes (VPC, security groups, endpoints)

Priority 3: Resolve threshold mismatch
├── Event description states 15-minute threshold
├── Detector config shows threshold_minutes: 5
└── Determine which is authoritative and correct the discrepancy
```

### Short-Term Actions (2–24 Hours)

```
Priority 4: Audit recent authentication events
├── Pull auth logs from IdP/application for the past 24 hours
├── Identify all JWT issuance events
├── Cross-reference against token usage logs
└── Manually identify any tokens issued but never used

Priority 5: Test detector end-to-end
├── Issue a test token
