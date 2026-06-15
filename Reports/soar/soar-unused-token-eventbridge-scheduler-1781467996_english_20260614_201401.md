# SOAR Report - unused-token-eventbridge-scheduler-1781467996 - 2026-06-14_20-13-16_UTC

- Trigger: eventbridge-scheduler
- Generated: 2026-06-14T20:13:16Z
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
# Security Event Analysis: Unused JWT Token After Successful Authentication

---

## Preliminary Note: Context Reconciliation

Before proceeding, a critical observation must be surfaced. **There is a material discrepancy between the narrative event description and the JSON context payload.** The narrative describes a specific user event (authentication → JWT issued → token unused within 15 minutes), but the JSON telemetry shows:

- `scanned: 0` — No tokens were actually evaluated
- `alerted: 0` — No alerts were generated
- `findings_total: 0` — No findings exist
- `findings_sample: []` — Empty result set
- `threshold_minutes: 5` — The detector threshold is 5 minutes, not 15

**This means the analysis must address two distinct concerns simultaneously:**

1. The **hypothetical/intended scenario** — what an unused token event *would* mean if real findings existed
2. The **actual operational concern** — the detector itself appears to be malfunctioning or misconfigured, which is itself a security risk

Both threads are analyzed below.

---

## 1. Severity Assessment

### Scenario A: If Real Unused Token Findings Existed
**Severity: MEDIUM (with escalation paths to HIGH)**

| Factor | Assessment |
|---|---|
| Confidentiality Impact | Medium — token represents a valid credential window |
| Integrity Impact | Low-Medium — depends on token scope/claims |
| Availability Impact | Low |
| Exploitability | Medium — requires token interception |
| Blast Radius | Scoped to token's permission set; potentially broad if privileged |

**Justification:**
A successfully issued but never-used JWT is anomalous by itself. Normal user behavior involves near-immediate token use following authentication. The gap between issuance and non-use suggests one of several threat conditions. The severity escalates significantly if:
- The token carries elevated privileges (admin, write, financial scopes)
- The user account is a service account or shared credential
- The source IP is anomalous or geographically inconsistent
- Multiple such events cluster around the same user or IP range

### Scenario B: Detector Producing Zero Scans (Actual Event)
**Severity: MEDIUM-HIGH**

**Justification:**
A security control that fires but scans nothing is a **detection gap**, not a clean bill of health. This is operationally equivalent to a smoke detector that activates but doesn't sample the air. The risk here is:
- Real unused token abuse may be occurring with **zero visibility**
- The EventBridge Scheduler is invoking the detector, confirming the pipeline is alive, but the detector logic is failing silently
- This creates a **false sense of security** — the most dangerous security posture

---

## 2. Possible Explanations Ranked by Likelihood

### For the Detector Malfunction (`scanned: 0`)

| Rank | Explanation | Likelihood | Evidence |
|---|---|---|---|
| 1 | **Token store query returning empty set** — The detector queries a token registry/cache that is empty, misconfigured, or pointing to the wrong environment/namespace | Very High | `scanned: 0` with a functioning scheduler strongly implies a data source issue |
| 2 | **Environment misconfiguration** — Detector is running in wrong environment (e.g., dev detector scanning prod token store path incorrectly, or vice versa) | High | Common in multi-environment deployments with shared EventBridge rules |
| 3 | **Token indexing pipeline broken** — Tokens are being issued but not written to the store the detector reads from (e.g., Redis TTL too short, DynamoDB write failure, missing async write) | High | Would explain both zero scans and zero findings |
| 4 | **IAM/permissions regression** — The Lambda/service running the detector lost read permissions to the token store after a recent deployment | Medium | Would typically produce an error, but silent failures are possible with some SDK configurations |
| 5 | **Detector logic bug post-deployment** — A recent code change introduced a short-circuit return before the scan loop executes | Medium | Requires recent deployment correlation |
| 6 | **Intentional suppression by an attacker** — An adversary with access to the detection pipeline disabled or neutered the scanner to operate undetected | Low-Medium | Sophisticated; would require significant prior access, but must not be dismissed |

### For the Unused Token Scenario (If Real)

| Rank | Explanation | Likelihood | Evidence Indicators |
|---|---|---|---|
| 1 | **User abandoned session** — Authenticated, was interrupted, closed browser/app before making any API call | Very High | No correlated API calls; single auth event; normal business hours |
| 2 | **Automated script/bot authentication test** — A health check or integration test that authenticates but doesn't proceed to API calls | High | Service account username; consistent timing patterns; non-human hours |
| 3 | **Credential stuffing probe** — Attacker obtained valid credentials, authenticated to confirm validity, then paused before exploitation (operational security delay) | Medium | Anomalous source IP; off-hours; new device fingerprint; no prior auth history |
| 4 | **Token harvesting for offline use** — Attacker authenticated, extracted the JWT for use in a different context (e.g., replaying against a different service that accepts the same token) | Medium | Especially relevant if JWT is not audience-restricted (`aud` claim absent or broad) |
| 5 | **Reconnaissance authentication** — Attacker mapping valid accounts without triggering downstream activity alerts | Medium | Multiple accounts showing same pattern; distributed source IPs |
| 6 | **MFA fatigue or push notification abandonment** — User approved MFA but then didn't complete the workflow | Medium | Relevant if MFA is push-based; correlate with MFA logs |
| 7 | **Session fixation or token theft in transit** — Token was intercepted post-issuance; attacker has the token, legitimate user never received it | Low-Medium | Would require MITM capability; TLS misconfiguration; compromised endpoint |
| 8 | **Application bug** — Client-side code received the token but failed to store/use it due to a software defect | Low | Would manifest as a pattern across many users, not isolated events |

---

## 3. Recommended Analyst Actions

### Immediate Actions (0–1 Hour)

#### For the Detector Malfunction

```
Priority 1: Establish whether this is a detection gap or a true zero-finding state

[ ] 1. Manually query the token store directly
       - Check Redis/DynamoDB/token registry for tokens issued in last 60 minutes
       - Compare count against auth logs for the same window
       - If auth logs show issued tokens but token store shows zero → write pipeline broken

[ ] 2. Review detector execution logs
       - Pull CloudWatch Logs for the Lambda/service invoked by EventBridge
       - Look for: exceptions, empty query results, permission errors, early returns
       - Check if scanned=0 is the result of an empty query or a skipped scan block

[ ] 3. Verify IAM permissions
       - Confirm the detector's execution role has read access to token store
       - Run: aws iam simulate-principal-policy for the relevant actions

[ ] 4. Check for recent deployments
       - Correlate scanned=0 onset with deployment history
       - Review git diff for detector code changes in last 72 hours

[ ] 5. Validate EventBridge rule target configuration
       - Confirm the rule is targeting the correct Lambda ARN/version/alias
       - Confirm environment variables are correctly set for the execution environment
```

#### For Unused Token Events (When Real Findings Exist)
