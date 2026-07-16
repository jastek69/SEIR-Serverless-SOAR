# Phase 2 End-to-End Test Results — 2026-07-16

Full verification of the jobs control plane (SEIR-Serverless-SOAR `modules/jobs`)
against the ComfyUI worker on the stability_ai GPU instance. All Phase 2
definition-of-done items passed. This file is committed to both repos
(`Reports/` in SEIR, `reports/` in stability_ai).

**Environment**
- SEIR control plane: 151 resources, applied fresh 2026-07-16 (state
  `global/lambda-terraform.tfstate`), API `c2iz64fra5` (us-west-2)
- Worker instance: `i-001c30cb0c68cd1e1` (g6e.xlarge, golden AMI baked
  2026-07-16), worker enabled at boot from the `/jobs/*` SSM handshake
- Test users: `admin.test` (group `admin`), `user.test` (group `user`),
  Hosted-UI Authorization Code + PKCE tokens (rbac-api scopes)

## Definition-of-done results

| # | Check | Result | Evidence |
| --- | --- | --- | --- |
| 1 | DCV password from SSM on a rebuilt instance (no manual passwd) | ✅ PASS | Verified at instance relaunch; `bootstrap.sh.tpl` chpasswd step in bootstrap.log |
| 2 | SEIR `terraform apply` creates queues, table, Lambdas, routes; API redeployed | ✅ PASS | 151 resources; `PythonDeployment` triggers include `module.jobs.deployment_trigger_hash` |
| 3 | Authenticated `POST /jobs` (type `comfyui_gen`) returns 202 + job_id | ✅ PASS | Jobs `07f3c8dc-2409-47ee-8204-f154356c0bc8`, `b2a0a406-48d5-4eba-b661-75440d545d66` |
| 4 | Unauthorized job type returns 403 | ✅ PASS | `{"error": "not entitled to job type: comfyui_gen"}` with entitlement temporarily stripped from the submit Lambda env (restored after) |
| 5 | Missing `rbac-api/*` scope returns 401 at the gateway | ✅ PASS | `USER_PASSWORD_AUTH` (mfa_bootstrap) tokens rejected `{"message":"Unauthorized"}` before Lambda ran |
| 6 | Worker picks up job, generates, uploads to S3, marks `succeeded` | ✅ PASS | `outputs/jobs/07f3c8dc…/job_smoke_test_00001_.png` (1.6 MiB); `metrics: {"duration_seconds": 0.4, "outputs_uploaded": 1}` (cache-hit render; first real render ~80 s incl. model load) |
| 7 | `GET /jobs/{id}` returns status + `result_prefix` | ✅ PASS | Full record returned incl. metrics |
| 8 | Other users' jobs return 404 (not 403, indistinguishable from missing) | ✅ PASS | `user.test` reading admin's job → 404; nonexistent id → 404 (identical) |
| 9 | Hand-stalled job → detector marks `stalled` → Bedrock report in S3 | ✅ PASS | Job `22025822-f804-4b72-9cd6-b8762ae75fc8`: detector flagged at 10:38:58 UTC, post-mortem at `reports/jobs/22025822….md` (3.9 KiB, Sonnet), `report_key` stamped |
| 10 | Instance terminated & rebuilt → worker resumes polling, zero manual steps | ✅ PASS | Proven at the 2026-07-16 instance replacement (bootstrap read SSM handshake, enabled service, long-polling within ~15 s of ComfyUI up) |

## Bugs found during testing (all fixed AND codified)

| Bug | Symptom | Fix |
| --- | --- | --- |
| DLQ visibility (30 s default) < reporter Lambda timeout (120 s) | `CreateEventSourceMapping` rejected on first apply | `visibility_timeout_seconds = 720` on DLQs (`modules/jobs/sqs.tf`) |
| `metrics` is a DynamoDB reserved keyword | Worker's final `succeeded` update threw `ValidationException`; job recorded `failed` although the render + upload succeeded (failure path thereby also proven) | Alias via `ExpressionAttributeNames` in worker `set_status` (`packer/provision.sh`); hot-patched on the live instance — **baked only after the next `packer build`** |
| Reporter denied `s3:PutObject` by bucket policy | `bucket_access_mode = "instance_and_root"` explicit deny; Bedrock ran but report couldn't land | `taaops-jobs-reporter-role` added to the bucket-policy exception list (stability_ai `s3.tf`, applied) |

## Operational gotchas confirmed (documented in README_worker-nodes.md)

- REST-API Cognito authorizer wants the **raw token** in `Authorization` — `Bearer <token>` → 401.
- Only Hosted-UI (Authorization Code + PKCE) tokens carry `rbac-api/*` scopes; `mfa_bootstrap.py` tokens can never pass the gateway scope check.
- Cognito cannot admin-reset a verified TOTP enrollment — a lost authenticator entry means delete + recreate the user.
- PKCE verifier/challenge pairs and the exchange must live in the same shell; codes are single-use, ~5 min.

## Post-test state / follow-ups

- Instance `i-001c30cb0c68cd1e1` to be **stopped** after testing (~$1.86/hr).
- **Rebake required** before the next instance replacement (metrics fix lives
  in `provision.sh` but not yet in the golden AMI).
- SEIR infra scheduled for `terraform destroy` after this test round; S3
  Bedrock reports archived to `Reports/07162026/` before teardown. The worker
  degrades gracefully when `/jobs/*` SSM params disappear (logs "control
  plane not deployed", instance behaves as Phase 1).
- Test artifacts to purge later: `outputs/jobs/*`, `reports/jobs/*` in the
  bucket (`scripts/order66.sh`); rotate the test users' password.
