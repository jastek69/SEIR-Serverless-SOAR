# SOAR Report - unused-token-manual-1781384202 - 2026-06-13_20-56-42_UTC

- Trigger: manual
- Generated: 2026-06-13T20:56:42Z
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

## Preliminary Note on Event Context

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON telemetry reveals a significant discrepancy between the narrative event description and the actual detector output.**

| Field | Value | Implication |
|---|---|---|
| `scanned` | `0` | No tokens were actually evaluated |
| `alerted` | `0` | No alerts were generated |
| `findings_total` | `0` | No findings exist |
| `findings_sample` | `[]` | Empty — no evidence of the described event |
| `trigger_source` | `manual` | Human-initiated scan, not automated detection |
| `threshold_minutes` | `5` | Detector threshold is 5 min, not 15 min as described |

> ⚠️ **The narrative describes a specific security event (user authenticated, JWT issued, token unused for 15 minutes), but the detector JSON shows zero scanned tokens and zero findings. This gap is itself a security concern and is treated as a primary finding throughout this analysis.**

This analysis therefore addresses **two parallel tracks**:
1. The **hypothetical/described event** (unused JWT post-authentication) as a security pattern
2. The **actual telemetry anomaly** (detector ran but scanned nothing) as a real, present concern

---

## 1. Severity Assessment

### Track 1 — Described Event (Unused JWT)

**Severity: LOW to MEDIUM (context-dependent)**
**CVSS Qualitative Range: 3.1 – 5.9**

#### Justification

In isolation, a successfully authenticated session where the issued JWT is never used is **not inherently malicious**. However, it becomes a meaningful signal when correlated with behavioral baselines, volume, and account context.

**Factors that elevate severity:**

| Escalating Factor | Severity Impact |
|---|---|
| High-privilege or service account | LOW → HIGH |
| Geolocation anomaly on authentication | LOW → MEDIUM-HIGH |
| Repeated pattern across multiple accounts | LOW → HIGH (credential stuffing indicator) |
| Authentication outside business hours | LOW → MEDIUM |
| Token issued via automated/API path | LOW → MEDIUM |
| No MFA on the authenticating account | LOW → MEDIUM |
| Token issued but session cookie also created | Potential session fixation vector |

**Factors that reduce severity:**

- User authenticated and then closed browser before app loaded
- Network interruption post-authentication
- Single isolated occurrence on a known user
- Authentication from a known, registered device

**Blast Radius Assessment:**

If this pattern represents credential validation (e.g., an attacker confirming credentials are valid without triggering downstream activity), the blast radius extends to:
- All resources the compromised account can access
- Downstream systems accepting the same JWT (if token is later exfiltrated and replayed)
- Audit log integrity (if attacker is probing detection thresholds)

---

### Track 2 — Detector Telemetry Anomaly

**Severity: MEDIUM**
**Justification:** A detector that runs but scans zero records is either misconfigured, operating against an empty/inaccessible data source, or has been interfered with. In a mature SOC environment, **silent detector failure is treated as a security event in its own right** — it creates a detection gap that an adversary could exploit or may already be exploiting.

---

## 2. Possible Explanations Ranked by Likelihood

### Track 1 — Why Would a JWT Be Issued But Never Used?

| Rank | Explanation | Likelihood | Notes |
|---|---|---|---|
| 1 | **Benign UX abandonment** — User authenticated, then navigated away, closed tab, or experienced a slow load | Very High | Most common in web apps; no security concern unless pattern repeats |
| 2 | **Network interruption** — Token issued server-side but response never reached client | High | Client would typically re-authenticate; check for follow-up auth events |
| 3 | **Credential validation probe** — Attacker confirms credentials are valid without triggering application-layer activity | Medium | Classic low-and-slow technique; look for geographic/ASN anomalies |
| 4 | **Automated script or bot** — Authentication performed programmatically; token not consumed because script logic failed or was testing auth endpoint only | Medium | Check user-agent strings, request cadence, and source IP reputation |
| 5 | **Token exfiltration for later replay** — Attacker obtained token via MITM or XSS and intends to use it outside the monitored window | Low-Medium | Requires token to still be valid; check token expiry configuration |
| 6 | **Threshold probing** — Adversary aware of the 15-minute detection window and deliberately staying under it | Low | Sophisticated; would require insider knowledge or prior reconnaissance |
| 7 | **Session fixation or pre-authentication token abuse** — Token generated as part of a session fixation attack | Low | Requires specific application vulnerability |
| 8 | **Misconfigured service account** — Service authenticated but downstream service failed to consume token | Low-Medium | Common in microservice architectures |

---

### Track 2 — Why Did the Detector Scan Zero Records?

| Rank | Explanation | Likelihood |
|---|---|---|
| 1 | **Detector misconfiguration** — Query, data source path, or filter is incorrectly configured | Very High |
| 2 | **Empty token store / wrong environment** — Detector pointed at wrong database, index, or environment (dev vs. prod) | High |
| 3 | **Data pipeline failure** — Token issuance events not being written to the store the detector queries | Medium |
| 4 | **Permissions issue** — Detector service account lacks read access to token store | Medium |
| 5 | **Deliberate tampering** — Adversary with access to detector configuration disabled or misdirected it | Low (but high impact if true) |
| 6 | **Race condition** — Tokens expired before detector ran, resulting in empty active token set | Low |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

```
Priority 1: Resolve the detector telemetry gap BEFORE investigating the described event.
A blind detector provides false assurance and must be treated as an open vulnerability.
```

**Step 1 — Validate Detector Integrity**
- [ ] Confirm the detector's data source connection is active and authenticated
- [ ] Manually query the token store directly to verify records exist
- [ ] Check detector service account permissions against the token store ACL
- [ ] Review detector configuration for environment targeting (dev/staging/prod)
- [ ] Examine detector logs for silent errors or exceptions

**Step 2 — Verify the Described Event Exists**
- [ ] Query authentication logs directly for the described event (successful auth + JWT issuance)
- [ ] Confirm whether the JWT in question appears in any access logs post-issuance
- [ ] Identify the user account, source IP, user-agent, and timestamp

**Step 3 — Contextual Enrichment (if event confirmed)**
- [ ] Geolocate the source IP; compare against user's historical login locations
- [ ] Check IP against threat intelligence feeds (VirusTotal, Shodan, AbuseIPDB)
- [ ] Determine if MFA was used during authentication
- [ ] Review account's recent authentication history for anomalies
- [ ] Check for concurrent sessions from different locations

### Short-Term Actions (1–24 Hours)

- [ ] Audit all
