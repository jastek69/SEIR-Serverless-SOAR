# SOAR Report - unused-token-eventbridge-scheduler-1781382842 - 2026-06-13_20-34-02_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-13T20:34:02Z
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

Before proceeding with the full analysis, a critical observation must be surfaced: **the provided JSON context reveals a detector invocation with zero scanned records, zero alerts, and no findings.** This materially shapes the analysis. The narrative event description (token issued, never used within 15 minutes) represents the *intended detection scenario* this system is designed to catch, but the current execution produced no data. Both dimensions — the threat model the detector targets and the operational health of the detector itself — require analysis.

---

## 1. Severity Assessment

### Threat Scenario Severity (If a Real Finding Were Present)
| Dimension | Rating | Justification |
|---|---|---|
| **Inherent Threat Severity** | **Medium (3/5)** | Unused tokens post-auth are a weak signal alone but gain severity through correlation |
| **Confidentiality Risk** | Medium | Token could be harvested for later replay or lateral movement |
| **Integrity Risk** | Low-Medium | No direct integrity impact unless token is used maliciously later |
| **Availability Risk** | Low | No direct availability impact |
| **Detection Confidence** | Low-Medium | Single behavioral indicator; high false-positive potential |

### Detector Health Severity (Current Execution)
| Dimension | Rating | Justification |
|---|---|---|
| **Operational Gap Severity** | **High (4/5)** | `scanned: 0` means the detector is blind — it cannot confirm absence of threat |
| **Detection Failure Risk** | High | A real attack would pass undetected if the scanner has no data to process |
| **Compliance Risk** | Medium-High | Audit trails and detection coverage SLAs may be violated |

### Justification for Dual Assessment

A detector that runs and finds nothing is fundamentally different from a detector that *cannot run* or *has nothing to scan*. The `scanned: 0` value is the most alarming signal in this entire event. It means one of the following is true:

- The token store/database was unreachable
- The query returned no rows due to a logic error or schema mismatch
- The time window filter eliminated all candidates before evaluation
- The detection pipeline itself is broken

**In a production SOC environment, a detector with `scanned: 0` should be treated as a potential blind spot until proven otherwise.**

---

## 2. Possible Explanations Ranked by Likelihood

### For the `scanned: 0` Condition (Primary Concern)

#### Rank 1 — Benign: No Tokens Exist in the Evaluation Window *(Likelihood: High)*
> The system may have no active JWT issuances within the threshold window at the time of scan. This is operationally valid during off-peak hours, maintenance windows, or early deployment phases.

**Evidence supporting this:** EventBridge Scheduler invocations are time-based; if the scan ran at 3 AM with no active users, zero records is expected.

**Risk:** Low if confirmed. High if assumed without verification.

---

#### Rank 2 — Operational: Data Source Connectivity or Query Failure *(Likelihood: Medium-High)*
> The detector may have failed to connect to the token store (Redis, DynamoDB, RDS, etc.), returned an empty result set due to a misconfigured query, or encountered a silent exception that was swallowed before populating `scanned`.

**Evidence supporting this:** The `findings_total: 0` combined with `scanned: 0` is suspicious — even in a healthy system, you'd expect *some* tokens to have been issued and evaluated unless the data pipeline is broken.

**Attack path if exploited:** An adversary who knows the detection pipeline is broken has an indefinite window to issue and stockpile tokens without triggering alerts.

---

#### Rank 3 — Configuration Drift: Threshold or Filter Misconfiguration *(Likelihood: Medium)*
> The `threshold_minutes: 5` value in the detector config may be misaligned with the token TTL or issuance timestamps. If tokens are evaluated before the 5-minute window closes, or if the timestamp comparison has a timezone/format bug, all records would be filtered out pre-scan.

**Example bug pattern:**
```python
# Incorrect: comparing naive datetime to timezone-aware datetime
issued_at = token_record["issued_at"]  # naive UTC string
threshold = datetime.now() - timedelta(minutes=5)  # local time
# If server is not UTC, this comparison silently excludes all records
if issued_at < threshold:
    scan_candidates.append(token_record)
```

---

#### Rank 4 — Adversarial: Detector Suppression or Log Manipulation *(Likelihood: Low)*
> A sophisticated adversary with write access to the detection pipeline, EventBridge rules, or the token store could suppress detector output. This is a low-likelihood but high-impact scenario.

**Indicators to look for:**
- Recent IAM policy changes affecting the detector's execution role
- EventBridge rule modifications in CloudTrail
- Lambda function code changes or environment variable tampering
- Unusual `PutEvents` or `DeleteRule` API calls

---

#### Rank 5 — Threat Scenario: Token Harvesting / Credential Stuffing Precursor *(Likelihood: Low for this specific event, but high strategic risk)*
> If real unused tokens *were* present, the most concerning explanation is that an attacker authenticated (via credential stuffing, phishing, or session hijacking) to obtain a valid JWT, then deliberately did not use it immediately — either to avoid triggering behavioral analytics, or to use it later from a different IP/device to evade geolocation-based controls.

**Attack chain:**
```
1. Attacker obtains valid credentials (phishing / credential stuffing / insider)
2. Attacker authenticates → JWT issued → logged
3. Attacker does NOT use token immediately (avoids velocity-based detection)
4. Token exfiltrated to C2 infrastructure
5. Token used hours/days later from different geography/device
6. By this point, "unused token" alert window has passed
```

**Blast radius:** Full account takeover with all permissions granted to the JWT's claims. If tokens carry elevated scopes (admin, write, billing), the impact is critical.

---

## 3. Recommended Analyst Actions

### Immediate (0–1 Hour)

#### Action 1: Validate Detector Operational Health
```
Priority: CRITICAL
Owner: SOC Tier 2 / Detection Engineering
```

- Query the token store directly (bypass the detector) to confirm whether any tokens were issued in the past 30 minutes
- Check Lambda execution logs for the `unused_token_detector` function:
  ```bash
  aws logs filter-log-events \
    --log-group-name /aws/lambda/unused_token_detector \
    --start-time $(date -d '1 hour ago' +%s000) \
    --filter-pattern "ERROR OR Exception OR scanned"
  ```
- Verify EventBridge Scheduler rule is correctly configured and the Lambda was actually invoked (not just scheduled):
  ```bash
  aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=unused_token_detector \
    --start-time $(date -d '2 hours ago' -u +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 3600 \
    --
