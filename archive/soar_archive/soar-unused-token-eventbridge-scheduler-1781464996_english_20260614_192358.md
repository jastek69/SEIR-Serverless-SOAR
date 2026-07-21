# SOAR Report - unused-token-eventbridge-scheduler-1781464996 - 2026-06-14_19-23-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T19:23:16Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the security event as described in the narrative (user authenticated, JWT issued, token unused within 15 minutes) does not align with the provided JSON context.** The JSON shows:

- `scanned: 0` — No tokens were actually scanned
- `alerted: 0` — No alerts were generated
- `findings_total: 0` — No findings exist
- `findings_sample: []` — Empty findings array
- `threshold_minutes: 5` — The detector threshold is 5 minutes, not 15

This discrepancy is itself a security-relevant finding. The analysis below addresses **both layers**:
- **Layer 1:** The theoretical security event described in the narrative
- **Layer 2:** The operational/detection integrity issue revealed by the JSON

---

## 1. Severity Assessment

### Layer 1 — Narrative Event (Unused JWT After Authentication)

| Attribute | Assessment |
|---|---|
| **Severity** | 🟡 **LOW–MEDIUM** (in isolation) / 🟠 **MEDIUM–HIGH** (in adversarial context) |
| **Confidence** | Low — insufficient corroborating signals |
| **Urgency** | Medium — requires triage within 1–4 hours |

**Justification:**

An unused JWT token following successful authentication is a **weak signal in isolation** but becomes significantly more concerning when viewed through an adversarial lens. The risk profile escalates based on context:

- **Credential harvesting operations** often involve authenticating to enumerate valid accounts or test stolen credentials without proceeding to use the session — the attacker has what they need (confirmation of valid credentials) and abandons the token deliberately.
- **Automated credential stuffing tools** frequently authenticate and discard tokens as part of bulk validation workflows.
- **Token exfiltration scenarios** are particularly dangerous: the token may have been issued, exfiltrated to an out-of-band channel, and used from a different host — meaning "unused" in your logs does not mean unused in reality, only unobserved within your detection perimeter.
- **Legitimate user abandonment** (closed browser, network drop, changed mind) is the most common benign explanation but cannot be assumed without corroboration.

The **blast radius** of a compromised but undetected JWT depends heavily on token scope. If the token carries broad permissions (admin roles, cross-service access, long TTL), the potential impact is severe even if the token appears dormant in your telemetry.

### Layer 2 — Detector Integrity Issue (JSON Context)

| Attribute | Assessment |
|---|---|
| **Severity** | 🔴 **HIGH** |
| **Confidence** | High — directly evidenced by JSON |
| **Urgency** | High — remediate within hours |

**Justification:**

A detector that scans zero tokens (`scanned: 0`) when it should be scanning active token inventory represents a **detection gap** — potentially a complete blind spot. This is more operationally dangerous than the original event because:

- You cannot detect what you cannot see
- The detector provides **false assurance** — it ran, produced no alerts, and an analyst might conclude "no issues" when in reality the scan was vacuous
- If this detector is part of a compliance control or SLA, it is silently failing

---

## 2. Possible Explanations Ranked by Likelihood

### Layer 1 — Narrative Event

#### Rank 1 — Benign User Abandonment *(~55% probability)*
The user authenticated but did not proceed. Common causes:
- Opened login page, got distracted, closed browser
- Network interruption post-authentication before first API call
- User authenticated to check something, decided not to proceed
- Mobile app backgrounded before first token use
- SSO flow initiated but user navigated away

**Detection note:** This is the null hypothesis. It should be assumed only after adversarial explanations are ruled out, not before.

#### Rank 2 — Automated Credential Validation / Stuffing *(~20% probability)*
Attackers running credential stuffing campaigns authenticate to confirm valid credentials. The token is irrelevant to them — they want the boolean: *"Does this password work?"* Indicators that elevate this probability:
- Authentication from unusual IP, ASN, or geolocation
- High velocity of similar events across multiple accounts
- User-agent string associated with automation tools (curl, python-requests, headless browsers)
- Authentication at unusual hours for the user's baseline

#### Rank 3 — Token Exfiltration (Used Out-of-Band) *(~12% probability)*
The token was issued, exfiltrated via a compromised client (malware, XSS, man-in-the-browser), and used from an attacker-controlled host. Your logs show "unused" because the usage originated from an IP/device not correlated to the original authentication event. This is a **high-impact, low-visibility** scenario.

Indicators:
- Subsequent API calls with the same token from a different IP
- Token appearing in threat intelligence feeds
- Concurrent sessions from geographically impossible locations

#### Rank 4 — Reconnaissance / Account Enumeration *(~8% probability)*
Authentication was used purely to confirm account existence and validity. Common in pre-attack reconnaissance phases. The attacker may return later with the same credentials or use the confirmed account list for targeted phishing.

#### Rank 5 — Application / Integration Bug *(~4% probability)*
A service account, CI/CD pipeline, or third-party integration authenticated but failed to use the token due to a bug, misconfiguration, or downstream service failure. Indicators:
- Service account or non-human identity involved
- Correlated application errors in the same timeframe
- Repeated pattern across multiple service accounts

#### Rank 6 — Insider Threat / Privilege Testing *(~1% probability)*
An insider authenticated to test whether their credentials still work (e.g., after a suspected account lockout warning) or to probe system access without leaving usage traces. Low probability but high impact if confirmed.

---

### Layer 2 — Detector Integrity Issue

#### Rank 1 — Token Store Not Populated / Wrong Data Source *(~40%)*
The detector queries a token store (Redis, DynamoDB, RDS) that is empty or misconfigured. Tokens may be stored in a different table, key prefix, or region than the detector expects.

#### Rank 2 — IAM/Permission Issue *(~25%)*
The Lambda or compute resource running the detector lacks read permissions on the token store. The scan silently returns 0 results rather than throwing an error — a dangerous failure mode.

#### Rank 3 — Token TTL Already Expired Before Scan *(~20%)*
Tokens expire before the EventBridge scheduler runs. If token TTL < scheduler interval, tokens are cleaned up before they can be scanned. The 5-minute threshold vs. a potentially shorter TTL creates a race condition.

#### Rank 4 — Code Logic Bug *(~10%)*
The detector code has a bug — incorrect query filter, off-by-one in timestamp comparison, wrong environment variable pointing to wrong store.

#### Rank 5 — EventBridge Misconfiguration *(~5%)*
The scheduler is triggering the wrong Lambda version, wrong environment, or the Lambda is receiving the event but exiting early due to an unhandled condition.

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### For the Narrative Event:

```
Priority 1: Enrich the authentication event
```

- [ ] Pull the full authentication log entry:
