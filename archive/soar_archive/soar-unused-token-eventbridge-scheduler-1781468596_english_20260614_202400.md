# SOAR Report - unused-token-eventbridge-scheduler-1781468596 - 2026-06-14_20-23-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T20:23:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and an empty `findings_sample`. This means the detector ran but found **nothing to analyze** — no tokens were scanned at all.

This discrepancy is itself a security-relevant finding and will be treated as a primary concern throughout this analysis. Both the hypothetical scenario (had tokens been found) and the actual detector failure are addressed.

---

## 1. Severity Assessment

### Actual Event (Detector Produced No Scan Results)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟡 **MEDIUM** | A detection control silently produced zero results, creating a blind spot |
| **Confidentiality Impact** | Low-Medium | Unknown — the absence of data means we cannot confirm or deny token abuse |
| **Integrity Impact** | Medium | Detection pipeline integrity is compromised |
| **Availability Impact** | Low | No service disruption observed |
| **Detection Gap Risk** | **High** | If tokens exist and are being abused, this detector would not catch them |

### Hypothetical Scenario (Had Unused Tokens Been Found)

| Dimension | Rating | Justification |
|---|---|---|
| **Overall Severity** | 🟠 **MEDIUM-HIGH** | Unused tokens suggest reconnaissance, automation probing, or credential harvesting |
| **Blast Radius** | Medium-High | Depends on token scope/claims; a privileged JWT sitting unused is a loaded weapon |

### Severity Justification — Deep Analysis

The threshold mismatch alone warrants attention: the narrative states **15 minutes** while the JSON detector threshold is **5 minutes**. This suggests either:

- The detector configuration has drifted from the documented policy
- Multiple detectors exist with inconsistent thresholds
- The narrative was written against a different version of the detection rule

A silent detector (`scanned: 0`) in a security pipeline is categorically dangerous. It satisfies alerting SLAs on paper while providing zero actual coverage — a **false sense of security** that is often worse than a known gap.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Primary Finding: `scanned: 0` (Detector Produced No Results)

---

#### 🥇 Rank 1 — Data Source / Query Failure (Likelihood: ~45%)

**Explanation:** The detector successfully invoked but failed to retrieve token records from the underlying data store (database, cache, token registry). This could be due to:

- A broken database connection or query timeout
- An empty token store (no active sessions exist — legitimate if the system is idle)
- A misconfigured query filter that excludes all records (e.g., wrong tenant ID, wrong time window, wrong index)
- A Redis/DynamoDB/token store that was flushed, rotated, or is in a degraded state

**Evidence Supporting This:**
- `scanned: 0` with `findings_total: 0` is the exact signature of a query returning an empty result set before evaluation logic runs
- No error fields are present in the JSON, suggesting the Lambda/function completed without exception — meaning it *thought* it succeeded

**Risk:** If the token store is genuinely empty, this is benign. If it's a query failure, every issued token is invisible to this control.

---

#### 🥈 Rank 2 — Legitimate System Idle State (Likelihood: ~25%)

**Explanation:** No users authenticated during the detection window. The system is genuinely idle (off-hours, maintenance window, low-traffic environment). The detector ran correctly and found nothing because nothing existed to find.

**Evidence Supporting This:**
- Zero findings with zero scanned is consistent with an empty dataset
- EventBridge Scheduler running on a fixed schedule will fire regardless of system activity

**Risk:** Low if confirmed. However, this should be **verified**, not assumed.

---

#### 🥉 Rank 3 — Token Store Architecture Mismatch (Likelihood: ~15%)

**Explanation:** The detector is querying the wrong location. JWTs may be stateless (no server-side registry), and the detector was designed for a stateful token system. If the application migrated from opaque tokens to stateless JWTs without updating the detector, the scanner will always return zero results.

**Evidence Supporting This:**
- Stateless JWTs by design leave no server-side footprint unless explicitly logged
- The detector name `unused_token_detector` implies it expects a token registry to exist

**Risk:** High architectural gap. This would mean the control has **never worked** in the current architecture.

---

#### 4th — Detector Code Bug / Logic Error (Likelihood: ~10%)

**Explanation:** A recent deployment introduced a bug — an off-by-one error in time window calculation, a null pointer that silently returns empty, or a feature flag that disabled scanning.

**Evidence Supporting This:**
- No error in the JSON output suggests silent failure rather than exception
- `threshold_minutes: 5` vs. the narrative's 15-minute window suggests configuration inconsistency that may extend to code

**Risk:** Medium. Requires code review and regression testing.

---

#### 5th — Active Evasion / Attacker Awareness (Likelihood: ~5%)

**Explanation:** A sophisticated attacker aware of the detection mechanism deliberately used the token within the 5-minute threshold to avoid triggering the unused-token alert, then abandoned it. This is low probability but non-zero in targeted attack scenarios.

**Evidence Supporting This:**
- Threat actors with insider knowledge or who have read exposed runbooks/IaC code may know detection thresholds
- Token used once for reconnaissance then discarded would not appear in this detector

**Risk:** High if true, but unlikely without other corroborating indicators.

---

### For the Hypothetical Scenario (Unused Token Found)

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | User authenticated then abandoned session (tab closed, distracted, UX friction) | ~40% |
| 2 | Automated script/bot authenticated but failed before making API calls | ~25% |
| 3 | Credential stuffing — attacker validated credentials but pivoted to different attack vector | ~15% |
| 4 | Token harvesting — attacker extracted the JWT for offline use or lateral movement | ~12% |
| 5 | Reconnaissance — attacker confirmed valid credentials exist, token stored for later use | ~8% |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Validate detector health
Priority 2: Confirm token store state  
Priority 3: Correlate with authentication logs
Priority 4: Resolve threshold discrepancy
```

---

#### Action 1: Validate the Detector Pipeline End-to-End

Run a **manual canary test** by injecting a known test token into the token store and re-triggering the detector:

```bash
# Manually invoke the detector Lambda (AWS example)
aws lambda invoke \
  --function-name unused_token_detector \
  --payload '{"source": "manual-test", "test_mode": true}' \
  --log-type Tail \
  output.json

# Decode the log output
aws lambda invoke ... | jq -r '.LogResult' | base64 --decode
```

**Expected outcome
