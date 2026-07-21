# SEIR-I Phase 11B — Human Incident Notes

<!--
FILL THIS IN YOURSELF — the lab requires these notes to be human-written
("Automation proves what happened. Humans must explain why.").
A facts appendix from the drill is at the bottom for reference;
delete it before submission if your instructor wants notes only.
-->

## 1. What was the initial symptom?
(What did the user/system experience?)

## 2. What evidence showed the system was failing?
(List specific files, logs, HTTP codes, timestamps.)

## 3. What was the root cause?
(Be precise. One sentence.)

## 4. What change fixed the issue?
(Exactly what was modified.)

## 5. How did you verify recovery?
(What evidence proves it is working again?)

## 6. What would you monitor next time to catch this faster?
(Logs, metrics, alarms.)

---

## Appendix — drill facts (collected 2026-07-20, all times UTC)

| Time | Event |
|---|---|
| 04:48:53 | Baseline probe: `POST /intake` → **200**, `event_id aeb54710…`, request `3991f7b4…`, Lambda duration 225 ms |
| 04:49:08 | Failure injected: ingress rule `sgr-0c349b628f438fa51` (TCP 3306 from `sg-0da2d34c54a32fd92`) revoked from RDS SG `sg-06bae7240197386e2` |
| 04:49:22 | Failure probe: `POST /intake` → **502** `DB_WRITE_FAILED`, request `858c430b…`, Lambda duration 5035 ms (pymysql connect_timeout=5s expired; TCP SYN to RDS:3306 silently dropped by SG) |
| 04:50:4x | Rule re-authorized as `sgr-091de41bc47f3970e`; description restored to match Terraform (`MySQL from intake Lambda only`) |
| 04:51:16 | Recovery probe: `POST /intake` → **200**, `event_id 168d1e54…`, request `15073c5b…`, 0.38 s |

Supporting facts:
- `sg_before_revoke_3306.out` and `sg_after_restore.out` have **identical SHA-256 hashes** — the restored security group state is byte-for-byte identical to baseline.
- The Lambda log (`logs_tail.out`) shows the duration signature: ~225 ms healthy vs ~5035 ms failing (connect timeout), with request IDs matching the curl captures.
- Nothing was redeployed: no Lambda, API Gateway, RDS, or Secrets Manager change — the fix was restoring the single revoked SG rule.
- Monitoring ideas seen in this stack: API Gateway 5xx alarm on the intake HTTP API; CloudWatch metric filter on `DB_WRITE_FAILED`; Lambda Duration p99 alarm (healthy ≈ 0.2 s, failing pegs at the 5 s connect timeout); EC2 CloudTrail event alerting on `RevokeSecurityGroupIngress` against the intake SGs.
