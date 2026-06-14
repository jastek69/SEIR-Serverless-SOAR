# SOAR Report - unused-token-eventbridge-scheduler-1781383442 - 2026-06-13_20-44-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:44:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the JSON context provided.** The JSON shows `scanned: 0`, `alerted: 0`, `findings_total: 0`, and `findings_sample: []`. This means the detector ran but found **nothing to analyze** — no tokens were scanned at all.

This discrepancy is itself a security-relevant finding and will be treated as a **primary concern** throughout this analysis alongside the theoretical event scenario described in the prompt.

---

## 1. Severity Assessment

### Scenario A: Unused JWT Token (Narrative Event)
**Severity: LOW to MEDIUM (contextual)**

| Factor | Assessment |
|---|---|
| Confidentiality Impact | Low — no data access confirmed |
| Integrity Impact | Low — no actions taken with token |
| Availability Impact | None |
| Likelihood of Malicious Activity | Low-Medium without corroborating signals |
| Detection Confidence | Medium — behavioral anomaly, not confirmed threat |

**Justification:**

An authenticated session where a JWT is issued but never used is a weak signal in isolation. However, it becomes meaningful when viewed through the lens of **credential harvesting**, **automated probing**, or **token pre-positioning** — attack patterns where an adversary validates credentials without immediately exploiting them to avoid triggering use-based detection controls. The 15-minute threshold adds temporal context but is not inherently alarming on its own.

The risk escalates significantly if:
- The authentication originated from an unusual IP, ASN, or geolocation
- The account has elevated privileges (admin, service account, API key owner)
- Multiple accounts show the same pattern simultaneously (credential stuffing sweep)
- The authentication method bypassed MFA

### Scenario B: Detector Malfunction (JSON Context — Primary Finding)
**Severity: MEDIUM to HIGH**

| Factor | Assessment |
|---|---|
| Detection Gap | HIGH — zero tokens scanned means blind spot exists |
| Operational Risk | HIGH — security control is non-functional |
| Blast Radius | Potentially organization-wide if all JWT activity is unmonitored |
| Urgency | High — requires immediate investigation |

**Justification:**

A detector that triggers, runs, and returns `scanned: 0` is a **silent failure**. This is arguably more dangerous than the event it was designed to detect. If no tokens are being scanned, the organization has a false sense of security — the control exists on paper but provides no actual coverage. This maps to **MITRE ATT&CK: Defense Evasion (T1562 - Impair Defenses)** if caused by an adversary, or to a critical **operational gap** if caused by misconfiguration.

---

## 2. Possible Explanations Ranked by Likelihood

### For the Unused Token Event (Narrative)

**Rank 1 — Benign User Behavior (Most Likely, ~55%)**
The user authenticated and then abandoned the session — closed the browser tab, got distracted, experienced a network interruption, or the client application failed silently after token issuance. This is the most statistically common explanation in enterprise environments, particularly for web applications with complex front-end initialization flows.

*Supporting indicators:* Single occurrence, business hours, known device/IP, no prior anomalies on account.

---

**Rank 2 — Automated Script or Integration Misconfiguration (~20%)**
A service account, CI/CD pipeline, or integration layer authenticated successfully but the downstream component that would consume the token failed, timed out, or was misconfigured. The token was issued to a process that never reached the consumption stage.

*Supporting indicators:* Non-human user agent, service account identity, authentication at off-hours, consistent pattern across multiple tokens.

---

**Rank 3 — Credential Validation Probe (~15%)**
An adversary who has obtained credentials (via phishing, credential stuffing, dark web purchase, or insider leak) authenticates to validate that the credentials are still active without triggering use-based alerting. This is a reconnaissance technique used before a more deliberate attack.

*Supporting indicators:* Authentication from unusual IP/ASN/country, VPN or Tor exit node, multiple accounts showing same pattern, authentication outside business hours, no prior login history from that location.

*Attack path:*
```
Adversary obtains credentials
        ↓
Validates credentials via auth endpoint
        ↓
JWT issued — adversary confirms account is live
        ↓
Token discarded (avoids triggering use-based detection)
        ↓
Adversary returns later with fresh authentication for actual attack
```

---

**Rank 4 — Token Pre-Positioning / Delayed Attack (~7%)**
The adversary authenticates and stores the token for later use, but the 15-minute window expires before use. This could indicate an attacker who was interrupted, or a tool that failed mid-execution. Less likely given JWT expiry typically makes pre-positioning impractical.

---

**Rank 5 — Automated Credential Stuffing Tool (~3%)**
A fully automated tool is cycling through a credential list, authenticating each one to build a list of valid accounts. The tool doesn't use tokens — it only cares about HTTP 200 responses from the auth endpoint.

*Supporting indicators:* High velocity of similar events across multiple accounts, identical user agents, sequential or pattern-based source IPs.

---

### For the Detector Malfunction (JSON Context)

**Rank 1 — Query/Data Source Misconfiguration (~50%)**
The EventBridge Scheduler triggered the detector correctly, but the underlying query (database query, log query, API call) returned no results due to a misconfigured filter, wrong table/index, incorrect time window, or environment mismatch (e.g., running against a staging token store instead of production).

**Rank 2 — Token Store Integration Failure (~25%)**
The detector cannot reach the token store (Redis, DynamoDB, database) due to a network policy change, IAM permission revocation, VPC routing issue, or service outage. It returns zero results because it cannot read any data.

**Rank 3 — Schema or Data Model Change (~15%)**
A recent deployment changed the token storage schema, field names, or data format. The detector's query no longer matches any records because it's looking for fields that no longer exist or have been renamed.

**Rank 4 — Intentional Tampering (~10%)**
An adversary or malicious insider has disabled or neutered the detector to create a blind spot before executing an attack. This is a low-probability but high-impact scenario that must be ruled out through change management review.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

**Step 1: Investigate the Detector Malfunction First**

This is the higher-priority finding. A broken detector means you cannot trust any absence of findings.

```
□ Review EventBridge Scheduler execution logs for the detector Lambda/function
□ Check CloudWatch Logs (or equivalent) for the detector's last 5 executions
□ Verify the detector's data source connection (token store reachability)
□ Confirm IAM/permissions for the detector role have not changed
□ Check if a recent deployment touched the token store schema or detector code
□ Compare detector behavior across environments (prod vs. staging)
□ Verify the token store actually contains tokens (manual spot-check)
```

**Step 2: Validate the Narrative Event Independently**

Since the detector returned zero findings, the narrative event (if real) was not captured
