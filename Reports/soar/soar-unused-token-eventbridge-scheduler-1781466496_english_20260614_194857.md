# SOAR Report - unused-token-eventbridge-scheduler-1781466496 - 2026-06-14_19-48-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:48:16Z
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

This discrepancy is itself a security-relevant finding and is treated as a primary concern throughout this analysis. Both the hypothetical scenario (if tokens *were* found unused) and the actual detector failure are addressed.

---

## 1. Severity Assessment

### Actual Event (Detector Produced No Scan Results)
| Attribute | Assessment |
|---|---|
| **Severity** | **MEDIUM** |
| **Confidence** | High |
| **Urgency** | Moderate — requires prompt investigation before next scheduled run |

**Justification:**
A detector that fires but scans zero records is a **silent failure** — arguably more dangerous than a detector that finds and alerts on anomalies. The `unused_token_detector` is a compensating control designed to catch post-authentication abuse patterns. If it is not scanning tokens, it provides a false sense of security. Any attacker who has obtained a valid JWT would be operating in a blind spot. The blast radius of this failure extends to every active session in the system.

### Hypothetical Scenario (Unused Token Found)
| Attribute | Assessment |
|---|---|
| **Severity** | **LOW-MEDIUM** (isolated) → **HIGH** (in aggregate or with other signals) |
| **Confidence** | Low in isolation |
| **Urgency** | Low standalone; escalate if correlated with other indicators |

**Justification:**
A single unused token is a weak signal. However, combined with indicators such as impossible travel, credential stuffing patterns, or bulk authentication events, it becomes a high-fidelity indicator of credential harvesting, automated probing, or token theft with delayed exploitation.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Actual Event (Zero Scans, Zero Findings)

#### Rank 1 — Token Store Query Failure or Misconfiguration *(~45% likelihood)*
The detector invoked successfully via EventBridge Scheduler but failed to connect to or query the token store (e.g., Redis, DynamoDB, RDS). This could be caused by:
- Expired or revoked IAM role permissions on the Lambda/compute executing the detector
- VPC misconfiguration preventing database access
- Token store schema change breaking the query
- Environment variable misconfiguration (wrong table name, endpoint, or index)

**Evidence supporting this:** `scanned: 0` with no error surfaced in the JSON suggests the scan loop was either never entered or exited immediately — consistent with an empty result set returned from a broken query rather than a runtime exception (which would typically produce a different event structure).

#### Rank 2 — Token Lifecycle Architecture Gap *(~30% likelihood)*
The system may not be persisting JWT metadata to a queryable store at issuance time. If JWTs are stateless (standard RS256/HS256 without a token registry), there is no record to scan. The detector was built assuming a token registry exists but the registry is empty, never populated, or the detector is pointed at the wrong data source.

**Risk implication:** Stateless JWTs by design cannot be revoked or tracked without a token registry. If the organization believes this detector is providing coverage but the registry is never populated, the entire detection capability is illusory.

#### Rank 3 — Scheduler Misconfiguration / Wrong Environment *(~15% likelihood)*
The EventBridge Scheduler may be triggering the detector against a non-production environment, a deprecated endpoint, or a region where no authentication activity occurs. The detector runs cleanly against an empty dataset and reports success.

#### Rank 4 — Intentional Behavior During Off-Peak Window *(~10% likelihood)*
If the scheduler fired during a maintenance window or a period of genuinely zero authentication activity, `scanned: 0` could be legitimate. However, this should be validated against authentication logs for the same time window.

---

### For the Hypothetical Scenario (Unused Token Found)

| Rank | Explanation | Likelihood | Risk Level |
|---|---|---|---|
| 1 | User authenticated and abandoned the session (tab closed, distracted, UX friction) | ~50% | Low |
| 2 | Automated script or integration test issued a token but did not complete the flow | ~20% | Low-Medium |
| 3 | Credential stuffing — attacker validated credentials but deferred exploitation | ~12% | High |
| 4 | Token harvesting — attacker obtained token via phishing or MitM, using it from a different host later | ~8% | Critical |
| 5 | Bot/scanner probing authentication endpoints without following through | ~7% | Medium |
| 6 | Broken client application failing to attach token to subsequent requests | ~3% | Low |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–2 Hours)

```
Priority 1: Validate detector operational status
```

1. **Inspect detector execution logs** — Pull CloudWatch Logs (or equivalent) for the Lambda/service executing `unused_token_detector`. Look for:
   - Exceptions or stack traces not surfaced in the event JSON
   - Database connection timeouts or permission denied errors
   - Empty result set vs. query never executed

2. **Verify token registry population** — Query the token store directly:
   ```sql
   -- Example: Check if token registry has any records
   SELECT COUNT(*), MAX(issued_at), MIN(issued_at)
   FROM jwt_token_registry
   WHERE issued_at >= NOW() - INTERVAL '24 HOURS';
   ```
   If this returns zero rows but authentication logs show successful logins, the registry is not being populated — **this is a P1 finding**.

3. **Cross-reference authentication logs** — Pull auth events for the same time window the detector scanned:
   ```
   Time window: [scheduler_trigger_time - threshold_minutes] to [scheduler_trigger_time]
   Query: auth_events WHERE event_type = 'TOKEN_ISSUED' AND timestamp IN window
   ```
   If auth events exist but `scanned: 0`, the detector has a data pipeline break.

4. **Check IAM permissions** — Verify the execution role for the detector has current, valid permissions to read from the token store. Look for recent policy changes.

### Short-Term Actions (2–24 Hours)

5. **Review EventBridge Scheduler configuration** — Confirm the scheduler is targeting the correct environment, region, and function ARN. Validate the schedule expression is firing at the intended frequency.

6. **Implement detector self-health reporting** — The detector should emit a metric or alarm when `scanned: 0` occurs during a window where authentication activity is known to exist. A detector that silently scans nothing is indistinguishable from a working detector in a quiet environment.

7. **Correlate with SIEM** — If the hypothetical unused token scenario applies, pivot on the user identity:
   - Check for concurrent sessions from different IPs
   - Review prior authentication history for anomalies
   - Check for password reset or MFA change events in the same window

### Ongoing Actions

8. **Establish baseline metrics** — Define expected `scanned` counts per time window based on authentication volume. Alert on deviations greater than 2 standard deviations.

9. **Test
