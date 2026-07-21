# RBAC Test RUNBOOK — Deployment of 2026-07-19

Copy-paste runbook for creating the RBAC test users and running the full test suite
against the **live deployment applied 2026-07-19** (210 resources). All IDs/URLs below
are the current live values; if the stack is ever destroyed and re-applied, regenerate
them from `terraform output` instead (see `docs/rbac-test.md`, the authoritative
reference this runbook condenses).

## Summary

The RBAC model has three independent layers, and the tests below exercise each one:

| Layer | Enforced by | Deny response | Test |
|---|---|---|---|
| 1. OAuth scope gate | API Gateway Cognito authorizer (`rbac-api/admin` or `rbac-api/user` scope required) | `401 Unauthorized` | Phase 5.1 (no/invalid token) |
| 2. Group check | Lambda (`cognito:groups` / `scope` claim) | `403 Forbidden` | Phase 5.2 (non-admin token) |
| 3. Traffic filter | WAFv2 managed rules | `403 Forbidden` | Phase 5.4 (XSS payload) |

Test flow: **create users → MFA enrollment → OAuth PKCE browser login (scope-bearing
tokens) → API tests → log/DynamoDB/SOAR verification.**

Key fact that drives the whole flow: `mfa_bootstrap.py` uses `USER_PASSWORD_AUTH`,
which can **never** issue a token carrying the custom `rbac-api/*` scopes — its tokens
always fail API Gateway with `401`. Only the Hosted UI **Authorization Code + PKCE**
flow (Phase 4) produces tokens the API accepts. Phase 3 exists solely to enroll MFA so
the Hosted UI login works.

### Live deployment values (2026-07-19)

| Item | Value |
|---|---|
| User pool | `us-west-2_ckJPlPz0T` |
| App client (no secret → PKCE) | `4hqt9ikctmesulmh0hbqbs00ta` |
| Hosted UI domain | `rbac-user-pool-domain.auth.us-west-2.amazoncognito.com` |
| Python API base | `https://d2zxhf2ieg.execute-api.us-west-2.amazonaws.com/prod` |
| Node API base | `https://uapov0k2d4.execute-api.us-west-2.amazonaws.com/prod` |
| Test users (created in Phase 2) | `admin.test` (group `admin`), `user.test` (group `user`) |

> The `APIGW-URL-PYTHON` / `APIGW-URL-NODE` outputs ending in `/tokens` are stale —
> the real resources are `/PythonResource` and `/NodeResource`.

---

## Phase 1 — Shell setup (once per Git Bash session)

Run everything in **Git Bash** from the repo root.

```bash
cd ~/aws/lambda/SEIR-Serverless-SOAR

# This shell's AWS_CA_BUNDLE points at a broken WSL path and kills every AWS call
unset AWS_CA_BUNDLE
# Stop Git Bash rewriting /aws/lambda/... log-group names into Windows paths
export MSYS_NO_PATHCONV=1

export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export COGNITO_APP_CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
export HOSTED_UI_DOMAIN="$(terraform output -raw cognito_hosted_ui_domain | sed 's#https://##')"
export API_PY_BASE="$(terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(terraform output -raw api_node_invoke_url)"

echo "USER_POOL_ID=$USER_POOL_ID"
echo "COGNITO_APP_CLIENT_ID=$COGNITO_APP_CLIENT_ID"
echo "HOSTED_UI_DOMAIN=$HOSTED_UI_DOMAIN"
echo "API_PY_BASE=$API_PY_BASE"
echo "API_NODE_BASE=$API_NODE_BASE"
```

**Expected (screenshot 1):** the five echo lines showing the values from the table above.

---

## Phase 2 — Create the Cognito test users

The `admin`/`user` **groups already exist** (Terraform creates them) — do not create
groups, only users.

```bash
aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username admin.test \
  --user-attributes Name=email,Value=admin.test@example.com Name=email_verified,Value=true \
  --message-action SUPPRESS --region "$AWS_REGION"

aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username user.test \
  --user-attributes Name=email,Value=user.test@example.com Name=email_verified,Value=true \
  --message-action SUPPRESS --region "$AWS_REGION"

aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" \
  --username admin.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"

aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" \
  --username user.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"

aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" \
  --username admin.test --group-name admin --region "$AWS_REGION"

aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" \
  --username user.test --group-name user --region "$AWS_REGION"
```

Verify:

```bash
aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username admin.test --region "$AWS_REGION"
aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username user.test --region "$AWS_REGION"
```

**Expected (screenshot 2):** each `admin-create-user` returns a JSON `User` block with
`"UserStatus": "FORCE_CHANGE_PASSWORD"` (the set-password calls then flip them to
`CONFIRMED`); the two verify calls show `admin.test` in group `admin` and `user.test`
in group `user`.

---

## Phase 3 — MFA enrollment (`--auto-totp`, both users)

This only enrolls MFA. The tokens it writes are **not** usable against the API — do not
source the generated `.env` files later.

```bash
py -3 scripts/mfa_bootstrap.py \
  --username admin.test \
  --region us-west-2 \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var ID_TOKEN \
  --track-token \
  --write-env Reports/admin_tokens.env \
  --auto-totp
```

```bash
py -3 scripts/mfa_bootstrap.py \
  --username user.test \
  --region us-west-2 \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var NON_ADMIN_ID_TOKEN \
  --track-token \
  --write-env Reports/non_admin_tokens.env \
  --auto-totp
```

Enter the password `ChangeMe123!` at the secure prompt (don't pass `--password` — the
`!` is shell-hostile).

**Expected (screenshot 3):** each run prints the new **MFA TOTP secret** and completes
authentication without manual code entry. **Save each user's secret in your
authenticator app (or a note) — Phase 4's Hosted UI login prompts for the current
6-digit code, and you will need it there.** `--track-token` also registers each ID
token in the DynamoDB `token-tracking` table, which feeds the unused-token/SOAR
pipeline verified in Phase 6.

> If a run fails mid-setup with a session error, just re-run it — if the user is
> already in `SOFTWARE_TOKEN_MFA` state the script prompts for a current code instead
> of generating a new secret.

---

## Phase 4 — Scope-bearing tokens (OAuth Authorization Code + PKCE)

Done **once per user**. Browser required. The Hosted UI keeps a session cookie, so:
`admin.test` in your normal browser, `user.test` in a **fresh incognito window**.

### 4a. admin.test

```bash
# PKCE pair
CODE_VERIFIER=$(openssl rand -base64 96 | tr -d '=+/\n' | cut -c1-64)
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '=')

echo "===== ADMIN.TEST authorize URL (open in your MAIN browser) ====="
echo "https://$HOSTED_UI_DOMAIN/oauth2/authorize?response_type=code&client_id=$COGNITO_APP_CLIENT_ID&redirect_uri=https%3A%2F%2Flocalhost%2Fcallback&scope=openid+rbac-api%2Fadmin+rbac-api%2Fuser&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
```

Open the printed URL, log in as `admin.test` / `ChangeMe123!`, enter the TOTP code from
Phase 3. The redirect to `https://localhost/callback?code=...` shows a browser
connection error — **that is expected**; copy the `code` value from the address bar.

```bash
CODE="PASTE_CODE_HERE"
OUT_FILE="Reports/oauth_admin.json"

curl -s -X POST "https://$HOSTED_UI_DOMAIN/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=$COGNITO_APP_CLIENT_ID" \
  -d "code=$CODE" \
  -d "redirect_uri=https://localhost/callback" \
  -d "code_verifier=$CODE_VERIFIER" > "$OUT_FILE"

# Self-check BEFORE exporting — must print username: admin.test with scope rbac-api/admin
python -c "import json,base64; d=json.load(open('$OUT_FILE')); p=d['access_token'].split('.')[1]; p+='='*(-len(p)%4); c=json.loads(base64.urlsafe_b64decode(p)); print('Self-check -', '$OUT_FILE', '-> username:', c['username'], '| scope:', c['scope'])"

ID_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['id_token'])")
ACCESS_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['access_token'])")
REFRESH_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['refresh_token'])")
export ID_TOKEN ACCESS_TOKEN REFRESH_TOKEN
```

**Expected (screenshot 4):** self-check prints
`username: admin.test | scope: ... rbac-api/admin rbac-api/user ...`.

### 4b. user.test (incognito window; new PKCE pair; different OUT_FILE and variable names)

```bash
CODE_VERIFIER=$(openssl rand -base64 96 | tr -d '=+/\n' | cut -c1-64)
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '=')

echo "===== USER.TEST authorize URL (open in a FRESH INCOGNITO window) ====="
echo "https://$HOSTED_UI_DOMAIN/oauth2/authorize?response_type=code&client_id=$COGNITO_APP_CLIENT_ID&redirect_uri=https%3A%2F%2Flocalhost%2Fcallback&scope=openid+rbac-api%2Fuser&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
```

Log in as `user.test`, copy the `code`, then:

```bash
CODE="PASTE_CODE_HERE"
OUT_FILE="Reports/oauth_user.json"    # NOT oauth_admin.json — #1 cause of mixed-up tokens

curl -s -X POST "https://$HOSTED_UI_DOMAIN/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=$COGNITO_APP_CLIENT_ID" \
  -d "code=$CODE" \
  -d "redirect_uri=https://localhost/callback" \
  -d "code_verifier=$CODE_VERIFIER" > "$OUT_FILE"

# Must print username: user.test with scope rbac-api/user (and NOT rbac-api/admin)
python -c "import json,base64; d=json.load(open('$OUT_FILE')); p=d['access_token'].split('.')[1]; p+='='*(-len(p)%4); c=json.loads(base64.urlsafe_b64decode(p)); print('Self-check -', '$OUT_FILE', '-> username:', c['username'], '| scope:', c['scope'])"

NON_ADMIN_ID_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['id_token'])")
NON_ADMIN_ACCESS_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['access_token'])")
NON_ADMIN_REFRESH_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['refresh_token'])")
export NON_ADMIN_ID_TOKEN NON_ADMIN_ACCESS_TOKEN NON_ADMIN_REFRESH_TOKEN
```

**Expected (screenshot 5):** self-check prints `username: user.test | scope: openid rbac-api/user`.

> Tokens expire after 1 hour. To refresh without redoing the browser dance, see
> `docs/rbac-test.md` section 4.1 (`grant_type=refresh_token`, no PKCE needed).

---

## Phase 5 — Run the RBAC tests

### 5.1 Negative auth — Layer 1 (expect `401`)

```bash
curl -i "$API_PY_BASE/PythonResource"
curl -i "$API_NODE_BASE/NodeResource"
```

**Expected (screenshot 6):** `HTTP/1.1 401 Unauthorized`, body `{"message":"Unauthorized"}` — both APIs.

### 5.2 Deny path — Layer 2, non-admin token (expect `403`)

```bash
curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
```

**Expected (screenshot 7):** `HTTP/1.1 403` from both — the token passes API Gateway
(it has `rbac-api/user` scope) and the **Lambda** group check denies it.
A `401` here means an expired token or one from `mfa_bootstrap.py` by mistake.

### 5.3 Allow path — admin token (expect `200`)

```bash
curl -i "$API_PY_BASE/PythonResource?name=Norrin" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=Norrin" -H "Authorization: $ACCESS_TOKEN"
```

**Expected (screenshot 8):** `HTTP/1.1 200 OK` with the Lambda greeting body from both APIs.

### 5.4 WAF block — Layer 3 (expect `403`)

```bash
curl -i "$API_PY_BASE/PythonResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ACCESS_TOKEN"
```

**Expected (screenshot 9):** `HTTP/1.1 403 Forbidden` — WAF blocks the XSS payload even
with a valid admin token. (SQLi-style payloads are informational — `200` or `403` both
acceptable; see `docs/rbac-test.md` 5.6.)

### 5.5 Scripted suite

```bash
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"
export SCHEDULE_NAME="$(terraform output -raw unused_token_schedule_name)"
export REPORTS_BUCKET="$(terraform output -raw incident_reports_bucket_name)"

bash ./scripts/rbac_test.sh
```

The script uses the `ID_TOKEN`/`ACCESS_TOKEN`/`NON_ADMIN_*` variables already exported
in Phase 4. **Never `source Reports/admin_tokens.env` or `non_admin_tokens.env` before
running it** — those are the scope-less MFA bootstrap tokens and would silently
overwrite the good ones.

**Expected (screenshot 10):** the script's pass/fail summary with all checks green.

---

## Phase 6 — Verify the evidence trail

### 6.1 Lambda logs

```bash
aws logs tail "$PY_LOG_GROUP" --region us-west-2 --since 15m | tee Reports/python_lambda_logs.txt
aws logs tail "$NODE_LOG_GROUP" --region us-west-2 --since 15m | tee Reports/node_lambda_logs.txt
```

**Expected (screenshot 11):** admin `200` requests plus the Lambda-side deny log lines
for the `403` tests.

### 6.2 DynamoDB token tracking

```bash
aws dynamodb scan --table-name token-tracking --max-items 20 --region us-west-2
```

**Expected (screenshot 12):** the rows registered by `--track-token` in Phase 3. Rows
whose `jti` matched an authenticated request show `used: true`. (OAuth Hosted-UI tokens
are not registered — only the bootstrap-tracked ones appear; this is a known gap, not
a failure.)

> **Timing matters:** bootstrap-tracked tokens are never marked used by the OAuth-token
> API tests (different `jti`), so the detector treats them as stale after
> **15 minutes** and `revoke_token_function` deletes the rows. An empty scan more than
> ~15 min after Phase 3 is the *success* state of the detection→revoke cycle, not a
> failure. To photograph rows, scan within 15 minutes of a bootstrap run — or capture
> the stronger before/after pair: scan right after a fresh `--track-token` run
> (rows present, `used: false`), then again 20 min later (empty) alongside
> `aws logs tail /aws/lambda/revoke_token_function --since 30m` showing the revoke.
> Note: a re-run of `mfa_bootstrap.py` for an already-enrolled user prompts for a
> current authenticator code (`--auto-totp` only applies to first-time MFA setup).

### 6.3 Unused-token detector → SOAR report (Bedrock)

```bash
aws lambda invoke \
  --function-name "unused_token_detector_function" \
  --payload '{"manual":true,"force_soar":true,"reason":"Operator-requested unused token review"}' \
  --region us-west-2 \
  --cli-binary-format raw-in-base64-out \
  unused-detector-response.json

cat unused-detector-response.json
```

**Expected (screenshot 13):** JSON containing `records_examined`, `matched`,
`soar_generated: true`, and populated `soar_key` / `soar_evidence_key` — the Bedrock
SOAR markdown+JSON artifacts land in the translation input bucket and are picked up
automatically by the translation Lambda.

---

## Cleanup (when done capturing)

```bash
aws cognito-idp admin-delete-user --user-pool-id "$USER_POOL_ID" --username admin.test --region "$AWS_REGION"
aws cognito-idp admin-delete-user --user-pool-id "$USER_POOL_ID" --username user.test --region "$AWS_REGION"
```

## Troubleshooting quick reference

| Symptom | Cause | Fix |
|---|---|---|
| Every AWS/terraform call fails with a CA/SSL path error | `AWS_CA_BUNDLE` still set | `unset AWS_CA_BUNDLE` (Phase 1) |
| `aws logs tail` says log group not found | Git Bash rewrote `/aws/lambda/...` | `export MSYS_NO_PATHCONV=1` (Phase 1) |
| `401` where you expected `200`/`403` | Token expired (1 h) or came from `mfa_bootstrap.py` | Refresh per rbac-test.md 4.1, or redo Phase 4 |
| Admin gets `403` | `ACCESS_TOKEN` missing `rbac-api/admin` scope | Re-run Phase 4a self-check; likely mixed-up OUT_FILE |
| Both users' tokens show `username: admin.test` | Hosted UI session cookie reissued admin code | Redo `user.test` login in a fresh incognito window |
| Hosted UI won't load right after an apply | New domain's CloudFront still propagating | Wait a few minutes, retry |
