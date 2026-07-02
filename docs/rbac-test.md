# End-to-End RBAC Test Runbook

Use this runbook to validate Cognito authentication, RBAC allow/deny behavior, WAF protection, and supporting AWS resources.

## Overall Flow
Flow: 1 (create users) → 2 (app client) → 3 (MFA enrollment for both users, including the user.test repeat) → 4 (OAuth scope-bearing tokens) → 4.1 (refresh) → 5 (run tests)

1. Create Cognito users and groups.
2. Ensure app client settings and environment variables are correct.
3. Get the admin tokens and export `ID_TOKEN` and `ACCESS_TOKEN`.
4. Get the non-admin tokens and export `NON_ADMIN_ID_TOKEN` and `NON_ADMIN_ACCESS_TOKEN`.
5. Run scripted and manual tests.
6. Verify logs, DynamoDB writes, and scheduler status.

## 1. Create Cognito users and groups

Create at least one admin user and one non-admin user in the user pool used by API auth.

The `admin` and `user` groups themselves do **not** need to be created manually — `terraform apply` already creates them declaratively via `aws_cognito_user_group.admin`/`.user` in cognito.tf, as part of standing up the pool. If you run a `create-group` call anyway, expect `GroupExistsException`; that's harmless, not a sign anything is wrong.

```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export ADMIN_POOL_ID="$(terraform output -raw cognito_admin_user_pool_id)"

echo "$USER_POOL_ID"
echo "$ADMIN_POOL_ID"

aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username admin.test --user-attributes Name=email,Value=admin.test@example.com Name=email_verified,Value=true --message-action SUPPRESS --region "$AWS_REGION"
aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username user.test --user-attributes Name=email,Value=user.test@example.com Name=email_verified,Value=true --message-action SUPPRESS --region "$AWS_REGION"

aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" --username admin.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"
aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" --username user.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"

aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" --username admin.test --group-name admin --region "$AWS_REGION"
aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" --username user.test --group-name user --region "$AWS_REGION"

aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username admin.test --region "$AWS_REGION"
aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username user.test --region "$AWS_REGION"
```

Expected results:

- The `admin` and `user` groups already exist (created by Terraform).
- Both users exist and are enabled.
- `admin.test` is in the `admin` group.
- `user.test` is in the `user` group.

To Delete users:
`aws cognito-idp admin-delete-user --user-pool-id "$USER_POOL_ID" --username admin.test --region "$AWS_REGION"`
`aws cognito-idp admin-delete-user --user-pool-id "$USER_POOL_ID" --username user.test --region "$AWS_REGION"`


AWS Console alternative:

1. Open AWS Console, go to Cognito, then User pools.
2. Open the user pool from `terraform output -raw cognito_user_pool_id`.
3. Go to User groups and create groups named `admin` and `user` if they do not already exist.
4. Go to Users and choose Create user.
5. Create `admin.test` and `user.test` with verified email attributes.
6. For each user, choose Set password and set a permanent password.
7. Add `admin.test` to group `admin` and `user.test` to group `user`.
8. Verify both users show status Confirmed/Enabled.


## 2. Ensure app client is correct

- Use a Cognito app client with no client secret for `USER_PASSWORD_AUTH`.
- Set required environment variables:

```bash
export AWS_REGION="us-west-2"
export COGNITO_APP_CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"

echo "$AWS_REGION"
echo "$COGNITO_APP_CLIENT_ID"

env | grep -E 'AWS_REGION|COGNITO_APP_CLIENT_ID'
```

Expected results:

- Variables are set in the current shell.

## 3. Get admin tokens

Primary path: use the MFA bootstrap helper.

There are three options for the admin token bootstrap flow.

### Option 1: default interactive setup

This is the manual TOTP entry path.

```bash
python scripts/mfa_bootstrap.py \
  --username admin.test \
  --region us-west-2 \
  --token-var ID_TOKEN \
  --track-token \
  --write-env Reports/admin_tokens.env

source Reports/admin_tokens.env
```

Expected results:

- If the user is in `MFA_SETUP`, the script prints a new MFA secret, you add it to your authenticator app, and then enter the current 6-digit code manually.
- If the user is already in `SOFTWARE_TOKEN_MFA`, the script prompts for a current authenticator code and does not generate a new secret.
- On success, it writes `Reports/admin_tokens.env`, and `source Reports/admin_tokens.env` loads `ID_TOKEN` and `ACCESS_TOKEN`.
- `--track-token` registers the Cognito ID token's `jti`, hash, issue time, and expiry in DynamoDB without storing the raw JWT.
- Successful authenticated Lambda/API paths now auto-mark that tracked JWT as used when the handler sees the matching `jti` or `origin_jti` claim.
- `scripts/rbac_test.sh` no longer invokes `update_token_function` as part of the happy path.
- The exported `ID_TOKEN_TRACKING_ID` remains useful for manual diagnostics or direct `update_token_function` invocation when you want to force a state change outside the normal request path.

### Option 2: email the MFA secret for authenticator setup

Note:

- The sender identity must be verified in SES.
- If SES is still in sandbox, both sender and recipient must be verified.

Verify SES identity:

```bash
aws sesv2 get-account --region "$AWS_REGION"
aws sesv2 list-email-identities --region "$AWS_REGION"
```

Expected checks:

- In the output of `list-email-identities`, confirm your sender appears with `VerifiedForSendingStatus` set to `true`.
- If the account is in SES sandbox, also verify the recipient email identity before using `--send-secret-to`.
- Console path: Amazon SES -> Configuration -> Verified identities -> Create identity (Email address) -> complete the email verification link.

```bash
py -3 scripts/mfa_bootstrap.py \
  --username admin.test \
  --region us-west-2 \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var ID_TOKEN \
  --track-token \
  --write-env Reports/admin_tokens.env \
  --send-secret-to "your-recipient@example.com" \
  --ses-from "your-verified-sender@example.com"
```

### Option 3: auto-generate TOTP

The script still prints the new MFA secret.
With `--auto-totp`, it generates the TOTP locally and submits immediately.
No manual code entry is required for the `MFA_SETUP` step.

Implementation notes:

- `--auto-totp` computes TOTP locally from the shared secret and submits it immediately.
- This avoids timing out while waiting on email or manual steps.
- TOTP generation uses HMAC-SHA1 over 30-second counters.
- The code logic lives in `mfa_bootstrap.py` inside `generate_totp` and the auto-TOTP branch in `MFA_SETUP`.

***`user.admin`:***
```bash
py -3 scripts/mfa_bootstrap.py \
  --username admin.test \
  --region us-west-2 \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var ID_TOKEN \
  --write-env Reports/admin_tokens.env \
  --auto-totp

source Reports/admin_tokens.env
```

***Repeat for `user.test`:***

```bash
py -3 scripts/mfa_bootstrap.py \
  --username user.test \
  --region us-west-2 \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var NON_ADMIN_ID_TOKEN \
  --track-token \
  --write-env Reports/non_admin_tokens.env \
  --auto-totp

source Reports/non_admin_tokens.env
```

Verify:

```bash
echo "${#NON_ADMIN_ID_TOKEN}"
echo "${#NON_ADMIN_ACCESS_TOKEN}"
```

If both values print non-zero lengths, you are ready to run the non-admin scope/RBAC deny test.

Notes:

- If the password contains `!` or other shell-sensitive characters, omit `--password` and enter it at the secure prompt.
- `--auto-totp` is recommended because it avoids session expiry during MFA setup.
- If you use `--send-secret-to`, email delivery can add delay and increase the chance of session timeout.

Expected results:

- `Reports/admin_tokens.env` is created.
- `ID_TOKEN` and `ACCESS_TOKEN` load successfully after `source Reports/admin_tokens.env`.
- This step only enrolls/authenticates the user with MFA. The `ACCESS_TOKEN` it produces does **not** carry the `rbac-api/admin` scope and will be rejected by API Gateway. See [4. Get scope-bearing access tokens](#4-get-scope-bearing-access-tokens-oauth-authorization-code--pkce) for the token you actually use against the API.

### 3.1 Manual one-time MFA bootstrap

Use this as a fallback for the admin user.

```bash
export AWS_REGION="us-west-2"
export CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
export USERNAME="admin.test"
export PASSWORD="ChangeMe123!"

SESSION=$(aws cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH --auth-parameters "USERNAME=$USERNAME,PASSWORD=$PASSWORD" --region "$AWS_REGION" --query Session --output text)
echo "$SESSION"

read SECRET_CODE MFA_SETUP_SESSION <<< "$(aws cognito-idp associate-software-token --session "$SESSION" --region "$AWS_REGION" --query '[SecretCode,Session]' --output text)"
echo "TOTP secret: $SECRET_CODE"

# Add SECRET_CODE to Google Authenticator or Authy as a manual key.
read -p "Enter current 6-digit TOTP code: " TOTP_CODE

VERIFY_SESSION=$(aws cognito-idp verify-software-token --session "$MFA_SETUP_SESSION" --user-code "$TOTP_CODE" --friendly-device-name "admin-test-device" --region "$AWS_REGION" --query Session --output text)
echo "$VERIFY_SESSION"

read ID_TOKEN ACCESS_TOKEN REFRESH_TOKEN <<< "$(aws cognito-idp respond-to-auth-challenge --client-id "$CLIENT_ID" --challenge-name MFA_SETUP --session "$VERIFY_SESSION" --challenge-responses "USERNAME=$USERNAME" --region "$AWS_REGION" --query 'AuthenticationResult.[IdToken,AccessToken,RefreshToken]' --output text)"

export ID_TOKEN
export ACCESS_TOKEN
echo "ID_TOKEN length: ${#ID_TOKEN}"
echo "ACCESS_TOKEN length: ${#ACCESS_TOKEN}"
```

Repeat the same manual bootstrap for non-admin if needed:

- Set `USERNAME="user.test"`.
- Set that user's password in `PASSWORD`.
- After Step 4, export the non-admin tokens with `export NON_ADMIN_ID_TOKEN="$ID_TOKEN"` and `export NON_ADMIN_ACCESS_TOKEN="$ACCESS_TOKEN"`.



## 4. Get scope-bearing access tokens (OAuth Authorization Code + PKCE)

Set your base variables once per shell session. Pull these from `terraform output` rather than hardcoding literals — the user pool ID and app client ID are regenerated every time the Cognito stack is destroyed/recreated, even if the Hosted UI domain prefix stays the same:

```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(env -u AWS_CA_BUNDLE terraform output -raw cognito_user_pool_id)"
export COGNITO_APP_CLIENT_ID="$(env -u AWS_CA_BUNDLE terraform output -raw cognito_user_pool_client_id)"
export HOSTED_UI_DOMAIN="$(env -u AWS_CA_BUNDLE terraform output -raw cognito_hosted_ui_domain | sed 's#https://##')"
export API_PY_BASE="$(env -u AWS_CA_BUNDLE terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(env -u AWS_CA_BUNDLE terraform output -raw api_node_invoke_url)"
```

If the Hosted UI authorize/login page errors out or doesn't load right after a fresh `terraform apply`, it's usually one of two things, not a config problem:

- **Stale values** — you're still using a `USER_POOL_ID`/`COGNITO_APP_CLIENT_ID` from before a destroy/recreate. Re-run the export block above to pick up the current ones.
- **New domain still propagating** — the Hosted UI domain's CloudFront distribution takes a few minutes to start responding right after `aws_cognito_user_pool_domain` is created. Wait a couple minutes and retry before assuming something's broken.

For each test user (repeat once for `admin.test`, once for `user.test`):

***`mfa_bootstrap.py`*** authenticates through Cognito's `USER_PASSWORD_AUTH` direct auth flow (`initiate-auth` / `respond-to-auth-challenge`). That flow only ever issues an access token with the default `aws.cognito.signin.user.admin` scope — it can never carry the custom `rbac-api/admin` / `rbac-api/user` scopes, regardless of the user's Cognito group. Since the API Gateway methods require `authorization_scopes = ["rbac-api/admin", "rbac-api/user"]` (api.tf:77, api.tf:189), a token from `mfa_bootstrap.py` is always rejected by API Gateway's built-in Cognito authorizer with `401 Unauthorized`, before Lambda ever runs — even for `admin.test`.

***Custom resource-server scopes*** are only granted through Cognito's OAuth 2.0 endpoints (`/oauth2/authorize` + `/oauth2/token`, reached via the Hosted UI). Use sections 3-4 above once per user to enroll them in MFA, then use this flow for the token you actually send to the API.

Prerequisite (already applied in this repo): `aws_cognito_user_pool_domain.cognito_rbac_pool_domain` in cognito.tf, and `supported_identity_providers = ["COGNITO"]` on the app client — required for the Hosted UI login page to render.

```bash
# 1. Generate a PKCE pair (required because the app client has no secret)
CODE_VERIFIER=$(openssl rand -base64 96 | tr -d '=+/\n' | cut -c1-64)
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '=')

# 2. Print the authorize URL and open it in a browser.
# Run ONE of these two blocks per browser session - not both back to back -
# so the printed label always tells you which URL you're looking at.

echo "===== ADMIN.TEST authorize URL (open this one first, in your main browser) ====="
echo "https://$HOSTED_UI_DOMAIN/oauth2/authorize?response_type=code&client_id=$COGNITO_APP_CLIENT_ID&redirect_uri=https%3A%2F%2Flocalhost%2Fcallback&scope=openid+rbac-api%2Fadmin+rbac-api%2Fuser&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
```

```bash
echo "===== USER.TEST authorize URL (open this one in a fresh incognito/private window) ====="
echo "https://$HOSTED_UI_DOMAIN/oauth2/authorize?response_type=code&client_id=$COGNITO_APP_CLIENT_ID&redirect_uri=https%3A%2F%2Flocalhost%2Fcallback&scope=openid+rbac-api%2Fuser&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
```

Log in as the target user and enter the TOTP code on the Hosted UI's MFA screen. It redirects to `https://localhost/callback?code=XXXX`; the browser shows a connection error since nothing listens on localhost — that's expected. Copy the `code` value out of the address bar.

The Hosted UI keeps a session cookie, so opening the `user.test` URL in the same browser you just used for `admin.test` will silently reissue an `admin.test` code instead of prompting for new credentials. Use a fresh incognito/private window (or a different browser entirely) for the second login, and check the decoded token's `username` claim afterward to confirm you actually got the user you expected.

```bash
# 3. Exchange the code for tokens. Use a distinct output file per user — rbac_test.sh
# section 5.2 reads both, and reusing one filename for both would overwrite the first.
# *** CHANGE OUT_FILE ON THE SECOND (user.test) RUN — this is the #1 source of ***
# *** mixed-up tokens: forgetting to switch this from oauth_admin.json.        ***
CODE="XXXX"           # paste from the browser address bar
OUT_FILE="Reports/oauth_admin.json"   # <-- use Reports/oauth_user.json for user.test

curl -s -X POST "https://$HOSTED_UI_DOMAIN/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=$COGNITO_APP_CLIENT_ID" \
  -d "code=$CODE" \
  -d "redirect_uri=https://localhost/callback" \
  -d "code_verifier=$CODE_VERIFIER" > "$OUT_FILE"

# 3.5. Self-check BEFORE exporting anything: confirms which real user this file
# now belongs to. If this doesn't say the user you expect, stop — you reused
# the wrong $OUT_FILE. Cheap to run every time, catches the mistake immediately
# instead of a confusing 401/403 several steps later.
python -c "import json,base64; d=json.load(open('$OUT_FILE')); p=d['access_token'].split('.')[1]; p+='='*(-len(p)%4); c=json.loads(base64.urlsafe_b64decode(p)); print('Self-check -', '$OUT_FILE', '-> username:', c['username'], '| scope:', c['scope'])"

# 4. Export the tokens (ID_TOKEN/ACCESS_TOKEN for admin.test, NON_ADMIN_ID_TOKEN/NON_ADMIN_ACCESS_TOKEN for user.test)
# Also keep REFRESH_TOKEN (NON_ADMIN_REFRESH_TOKEN for user.test) - see 4.1 to
# refresh without repeating the browser login once ID_TOKEN/ACCESS_TOKEN expire.
# *** CHANGE THE VARIABLE NAMES ON THE SECOND (user.test) RUN TOO — this is the ***
# *** #2 source of mixed-up tokens: reusing ID_TOKEN/ACCESS_TOKEN both times.    ***
ID_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['id_token'])")
ACCESS_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['access_token'])")
REFRESH_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['refresh_token'])")
export ID_TOKEN ACCESS_TOKEN REFRESH_TOKEN

# 5. Verify the scope and username actually landed correctly
echo "$ACCESS_TOKEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | python -m json.tool
```

Expected results:

- Step 3.5's self-check prints the username you actually just authenticated as — confirm it matches before doing anything else.
- The decoded payload's `scope` field contains `rbac-api/admin` (admin.test) or `rbac-api/user` (user.test) — not just `aws.cognito.signin.user.admin`.
- The decoded payload's `username` field matches the user you intended to log in as.
- Repeat once per user: `Reports/oauth_admin.json` for `admin.test`, keeping its tokens as `ID_TOKEN`/`ACCESS_TOKEN`; `Reports/oauth_user.json` for `user.test`, exporting its tokens as `NON_ADMIN_ID_TOKEN`/`NON_ADMIN_ACCESS_TOKEN` instead (repeat step 4 with those variable names and `OUT_FILE=Reports/oauth_user.json`).

## 4.1 Refresh an expired token (no browser login required)

`ID_TOKEN`/`ACCESS_TOKEN` expire after 1 hour (`expires_in: 3600` in the token response). If a curl call starts returning `401` again after previously working, check expiry before assuming something broke:

```bash
echo "$ACCESS_TOKEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | python -c "import json,sys,time; c=json.load(sys.stdin); print('exp:', c['exp'], '| now:', int(time.time()), '| expired:', c['exp'] < time.time())"
```

If it's expired, you do **not** need to redo the whole browser login/PKCE dance — Cognito's `refresh_token` grant mints a new `ID_TOKEN`/`ACCESS_TOKEN` from the `REFRESH_TOKEN` you saved in step 4 of section 4:

```bash
OUT_FILE="Reports/oauth_admin.json"   # or Reports/oauth_user.json for the non-admin token

curl -s -X POST "https://$HOSTED_UI_DOMAIN/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "client_id=$COGNITO_APP_CLIENT_ID" \
  -d "refresh_token=$REFRESH_TOKEN" > "$OUT_FILE"

ID_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['id_token'])")
ACCESS_TOKEN=$(python -c "import json; print(json.load(open('$OUT_FILE'))['access_token'])")
export ID_TOKEN ACCESS_TOKEN
```

Notes:

- No `code_verifier`/PKCE is needed here — that's only required for the initial `authorization_code` exchange, not for `refresh_token`.
- Use `$NON_ADMIN_REFRESH_TOKEN` (writing to `NON_ADMIN_ID_TOKEN`/`NON_ADMIN_ACCESS_TOKEN`) to refresh the non-admin side instead.
- Cognito does not rotate the refresh token by default — the response won't include a new `refresh_token`, so keep reusing the original `$REFRESH_TOKEN` for future refreshes rather than overwriting it from this response.
- The refresh token itself is long-lived (30 days by default) but not infinite. If a `refresh_token` grant call itself fails (e.g. `NotAuthorizedException`/`invalid_grant`), the refresh token has expired or been revoked — at that point you must redo the full browser-based flow in section 4 from step 2 onward.

## 5. Run tests

### RBAC validation tests

```bash
export API_PY_BASE="$(terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(terraform output -raw api_node_invoke_url)"

echo "API_PY_BASE=$API_PY_BASE"
echo "API_NODE_BASE=$API_NODE_BASE"

curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"

curl -i "$API_PY_BASE/PythonResource?name=Norrin" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=Norrin" -H "Authorization: $ACCESS_TOKEN"
```

`ACCESS_TOKEN` / `NON_ADMIN_ACCESS_TOKEN` here must be the tokens from [section 4](#4-get-scope-bearing-access-tokens-oauth-authorization-code--pkce), not the ones written by `mfa_bootstrap.py` directly.

Expected results:

- `403` for both non-admin requests.
- `200` for both admin requests.
- If admin returns `403`, decode `ACCESS_TOKEN` and confirm it contains the required `rbac-api/admin` scope.
- If admin or non-admin returns `401`, the token most likely came from `mfa_bootstrap.py` (`USER_PASSWORD_AUTH`) instead of the OAuth flow in section 4 — that token never carries custom scopes and API Gateway rejects it outright.

### Capture logs

```bash
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"

echo "PY_LOG_GROUP=$PY_LOG_GROUP"
echo "NODE_LOG_GROUP=$NODE_LOG_GROUP"

export MSYS_NO_PATHCONV=1
aws logs tail "$PY_LOG_GROUP" --region us-west-2 --since 5m | tee Reports/python_lambda_logs.txt
aws logs tail "$NODE_LOG_GROUP" --region us-west-2 --since 5m | tee Reports/node_lambda_logs.txt
```

Note: `MSYS_NO_PATHCONV` disables Git Bash path conversion. `tee` writes the raw tail output to `Reports/*.txt` while still printing it to the terminal — re-running this overwrites the previous capture, so rename or copy the file first if you want to keep a specific run's output.

### 5.1 Validate Terraform and capture outputs

```bash
terraform validate -no-color
terraform output -raw api_python_invoke_url
terraform output -raw api_node_invoke_url
terraform output -raw python_lambda_log_group
terraform output -raw node_lambda_log_group
terraform output -raw unused_token_schedule_name
```

Expected results:

- `terraform validate` returns success.
- API and log output values are non-empty.

### 5.2 Set convenience variables for `rbac_test.sh`

`rbac_test.sh` uses whatever `ID_TOKEN` / `ACCESS_TOKEN` / `NON_ADMIN_ID_TOKEN` / `NON_ADMIN_ACCESS_TOKEN` are already exported in your shell, and only checks that they're unexpired — not that they carry the right scope. **Do not** `source Reports/admin_tokens.env` or `source Reports/non_admin_tokens.env` here: those files come from `mfa_bootstrap.py`'s `USER_PASSWORD_AUTH` flow and never carry the `rbac-api/admin` / `rbac-api/user` scope (see [section 4](#4-get-scope-bearing-access-tokens-oauth-authorization-code--pkce)). Sourcing them would silently overwrite good tokens with ones API Gateway will reject.

Instead, make sure these are set from the OAuth flow in section 4 (redo it if they've expired — they last 1 hour):

```bash
ID_TOKEN=$(python -c "import json; print(json.load(open('Reports/oauth_admin.json'))['id_token'])")
ACCESS_TOKEN=$(python -c "import json; print(json.load(open('Reports/oauth_admin.json'))['access_token'])")
export ID_TOKEN ACCESS_TOKEN

NON_ADMIN_ID_TOKEN=$(python -c "import json; print(json.load(open('Reports/oauth_user.json'))['id_token'])")
NON_ADMIN_ACCESS_TOKEN=$(python -c "import json; print(json.load(open('Reports/oauth_user.json'))['access_token'])")
export NON_ADMIN_ID_TOKEN NON_ADMIN_ACCESS_TOKEN

export API_PY_BASE="$(terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(terraform output -raw api_node_invoke_url)"
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"
export SCHEDULE_NAME="$(terraform output -raw unused_token_schedule_name)"
export REPORTS_BUCKET="$(terraform output -raw incident_reports_bucket_name)"

echo "$AWS_REGION"
echo "$COGNITO_APP_CLIENT_ID"
echo "$API_PY_BASE"
echo "$API_NODE_BASE"
echo "$PY_LOG_GROUP"
echo "$NODE_LOG_GROUP"
echo "$SCHEDULE_NAME"
echo "$REPORTS_BUCKET"
```

Then run:

```bash
bash ./scripts/rbac_test.sh
```

### 5.3 Negative auth test (no token)

```bash
curl -i "$API_PY_BASE/PythonResource"
curl -i "$API_NODE_BASE/NodeResource"
```

Expected: `401 Unauthorized`.

### 5.4 Positive auth test (admin token)

```bash
curl -i "$API_PY_BASE/PythonResource?name=theo" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=theo" -H "Authorization: $ACCESS_TOKEN"
```

Expected: `200 OK` when the access token has the required API Gateway scope and the Lambda sees admin group membership.

If `ID_TOKEN_TRACKING_ID` is present and maps to the request JWT claims (`jti` or `origin_jti`), the tracked DynamoDB item should transition to `status=used` and `used=true` automatically.

### 5.5 RBAC deny-path test (non-admin token)

```bash
curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
```

Expected: `403`.

API Gateway's `authorization_scopes` now accepts either `rbac-api/admin` or `rbac-api/user` (see the changelog entry below), so any authenticated `rbac-api` caller reaches Lambda, and Lambda's group/scope check returns the actual `403` for non-admins.

If you get `401` instead, it's either an expired token or one obtained via `mfa_bootstrap.py` — that flow never carries a custom scope at all, so API Gateway rejects it outright regardless of expiry. Refresh via the Authorization Code + PKCE flow in [section 4](#4-get-scope-bearing-access-tokens-oauth-authorization-code--pkce), not `mfa_bootstrap.py`, then re-export `NON_ADMIN_ACCESS_TOKEN`.

### 5.6 WAF tests

Run strict block payloads first. These should return `403 Forbidden` when WAF is enforcing block mode.

```bash
curl -i "$API_PY_BASE/PythonResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ACCESS_TOKEN"
```

Expected strict results:

- HTTP `403` with API Gateway `Forbidden` response body.
- API Gateway access logs show `wafResponseCode: WAF_BLOCK` and `wafStatus: 403`.

Run SQLi-style payloads as informational checks. These may be `200` or `403` depending on current managed rule coverage and sensitivity.

```bash
curl -i "$API_PY_BASE/PythonResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $ACCESS_TOKEN"
```

Expected informational results:

- `403` is acceptable and indicates stronger blocking.
- `200` is acceptable if logs still show WAF evaluated and allowed (`wafResponseCode: WAF_ALLOW`).
- Treat `200` here as a signal to tune WAF rules, not as an RBAC or API regression.

### 5.7 DynamoDB checks

```bash
aws dynamodb describe-table --table-name token-tracking --region us-west-2
aws dynamodb scan --table-name token-tracking --max-items 20 --region us-west-2

aws dynamodb get-item --table-name token-tracking --key "{\"token_id\":{\"S\":\"$ID_TOKEN_TRACKING_ID\"}}" --region us-west-2 --query "Item.{token_id:token_id.S,status:status.S,used:used.BOOL,updated_at_iso:updated_at_iso.S,last_used_request_id:last_used_request_id.S}" --output table

aws dynamodb describe-table --table-name token-revocation --region us-west-2
aws dynamodb scan --table-name token-revocation --max-items 20 --region us-west-2
```

Optional token-hash lookup:

```bash
aws dynamodb query --table-name token-tracking --index-name token-hash-index --key-condition-expression "token_hash = :h" --expression-attribute-values '{":h":{"S":"replace_with_hash"}}' --region us-west-2
```

### 5.8 Direct Lambda invocation checks

Successful authenticated API calls now update tracked JWT records automatically. Use the direct invocation below only for manual diagnostics, contract testing, or forced state changes outside the normal API request flow.

`scripts/rbac_test.sh` does not call `update_token_function` for the normal auth flow.

```bash
aws lambda invoke --function-name update_token_function --payload '{"body":"{\"token_id\":\"replace_token_id\",\"action\":\"used\"}"}' update-token-response.json --region us-west-2
cat update-token-response.json

aws lambda invoke --function-name immediate_revoke_66_function --payload '{"token_hash":"replace_with_hash","reason":"manual_test"}' revoke-response.json --region us-west-2
cat revoke-response.json
```

### 5.9 EventBridge scheduler checks

```bash
aws scheduler get-schedule --name "$SCHEDULE_NAME" --group-name default --region us-west-2

aws lambda invoke --function-name unused_token_detector_function --payload '{}' unused-detector-response.json --region us-west-2
cat unused-detector-response.json
```

Expected results:

- Scheduler exists and points to `unused_token_detector_function`.
- Direct invoke returns a JSON body with `records_examined`, `matched`, `alerted`, and `threshold_minutes`.
- `soar_generated` is `true` when a report is generated.
- With `SOAR_GENERATE_ON_EMPTY=true` (current default), report generation occurs even when no stale unused tokens are found.

`records_examined` is DynamoDB `ScannedCount`. `matched` is the number of active-unused
tracking records returned by the detector filter. A zero `matched` value does not by
itself indicate a detector or DynamoDB failure.

What to look for in `unused-detector-response.json`:
1. soar_generated should be true
2. soar_key should be populated
3. soar_evidence_key should be populated



### Manual SOAR Invoke

Use this when you want to force a SOAR artifact immediately without waiting for the five-minute schedule and even if no stale tokens are currently present.

Payload:

```json
{
  "manual": true,
  "force_soar": true,
  "reason": "Operator-requested unused token review"
}
```

CLI example:

```bash
aws lambda invoke \
  --function-name "unused_token_detector_function" \
  --payload '{"manual":true,"force_soar":true,"reason":"Operator-requested unused token review"}' \
  --region us-west-2 \
  --cli-binary-format raw-in-base64-out \
  unused-detector-response.json

cat unused-detector-response.json
```

Expected results:

- Response includes `soar_generated`, `soar_key`, and `soar_evidence_key`.
- The detector uploads two separate artifacts to the translation input bucket:
  - `soar/soar-<incident-id>.md`
  - `soar/soar-<incident-id>.json`
- The translation Lambda then processes those S3 objects automatically.

### Download translated reports

```bash
mkdir -p Reports
aws s3 sync "s3://$REPORTS_BUCKET/reports/" "Reports/" --region us-west-2
```

Or Set ENV:
```bash
REPORTS_BUCKET=$(terraform output -raw incident_reports_bucket_name)
aws s3 sync "s3://$REPORTS_BUCKET/reports/" "Reports/" --region us-west-2
```

Check:
```bash
find Reports/soar -type f | sort | tail -n 20
```

Expected local results:

- Downloaded files appear under the repo's `Reports/` directory.
- Nested S3 keys are preserved locally. For example, translated SOAR files written as `reports/soar/...` in S3 will appear under `Reports/soar/...` locally.
- Re-running `aws s3 sync` only downloads new or changed files.

Optional checks:

```bash
aws s3 ls "s3://$REPORTS_BUCKET/reports/" --recursive --region us-west-2
find Reports -type f | sort
```

AWS Console path:

1. Open Lambda.
2. Select `unused_token_detector_function`.
3. Create a test event.
4. Paste the manual payload shown above.
5. Click Test.

### 5.10 CloudWatch and WAF logs

```bash
aws logs tail "$PY_LOG_GROUP" --region us-west-2 --since 15m
aws logs tail "$NODE_LOG_GROUP" --region us-west-2 --since 15m

aws logs tail "$(terraform output -raw python_api_gateway_access_log_group)" --region us-west-2 --since 15m
aws logs tail "$(terraform output -raw node_api_gateway_access_log_group)" --region us-west-2 --since 15m
```

Optional WAF logs:

```bash
aws s3 ls "s3://$(terraform output -raw waf_logs_bucket)" --recursive --region us-west-2
aws logs tail "$(terraform output -raw waf_log_group)" --region us-west-2 --since 15m
```

## 6. Pass criteria summary

- No-token calls return `401`.
- Valid admin token calls return `200`.
- Non-admin token calls return `403`.

## 7. Generated report document

The script now writes the full RBAC test transcript to a Markdown report in the Reports directory:

```bash
Reports/rbac_test_report.md
```

The report captures:
- All command output from the RBAC test run.
- Strict WAF XSS block result (`PASS`/`FAIL`) with Python and Node HTTP statuses.
- Informational SQLi-style WAF statuses for both APIs.
- DynamoDB tables show expected writes for token tracking and revocation flows.
- Scheduler exists and detector invocation succeeds.
- Manual detector invoke can force SOAR generation and returns artifact keys.
- CloudWatch, API Gateway, and WAF logs show the corresponding request records.

## Notes

- `scripts/mfa_bootstrap.py` is the preferred token path for first-time MFA users.
- Account selection is determined by the username and password you provide for the bootstrap helper or Cognito auth flow.
- Run token retrieval once per user type: admin first, non-admin second.
- Token env files under `Reports/` are local artifacts and should not be committed.

## Quick bootstrap recovery sequence

Use this when bootstrap returns `UserNotFoundException`.

### 1. Confirm tools and Python launcher

```bash
command -v py
py -3 --version
command -v python3
```

### 2. Set runtime variables

***Steps for `admin.test`:***
```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
export USERNAME="admin.test"
export PASSWORD="Th3D4rkS1d3@"

echo "AWS_REGION=$AWS_REGION"
echo "USER_POOL_ID=$USER_POOL_ID"
echo "CLIENT_ID=$CLIENT_ID"
echo "USERNAME=$USERNAME"
```

***Same steps for `user.test`***
```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
export USERNAME="user.test"
export PASSWORD="Th3D4rkS1d3@"

echo "AWS_REGION=$AWS_REGION"
echo "USER_POOL_ID=$USER_POOL_ID"
echo "CLIENT_ID=$CLIENT_ID"
echo "USERNAME=$USERNAME"
```


### 3. Verify whether the user exists in the API auth user pool

```bash
aws cognito-idp list-users --user-pool-id "$USER_POOL_ID" --region "$AWS_REGION" --query 'Users[].Username' --output text
aws cognito-idp admin-get-user --user-pool-id "$USER_POOL_ID" --username "$USERNAME" --region "$AWS_REGION"
```

### 4. If missing, create the user and attach the admin group

```bash
aws cognito-idp create-group --user-pool-id "$USER_POOL_ID" --group-name admin --region "$AWS_REGION"
aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username "$USERNAME" --user-attributes Name=email,Value=admin.test@example.com Name=email_verified,Value=true --message-action SUPPRESS --region "$AWS_REGION"
aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" --username "$USERNAME" --password "$PASSWORD" --permanent --region "$AWS_REGION"
aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" --username "$USERNAME" --group-name admin --region "$AWS_REGION"
```

### 5. Run MFA bootstrap and load tokens

```bash
py -3 scripts/mfa_bootstrap.py \
  --username "$USERNAME" \
  --region "$AWS_REGION" \
  --client-id "$CLIENT_ID" \
  --password "$PASSWORD" \
  --auto-totp \
  --token-var ID_TOKEN \
  --write-env Reports/admin_tokens.env

source Reports/admin_tokens.env
```


What to look for in unused-detector-response.json:

soar_generated should be true
soar_key should be populated
soar_evidence_key should be populated

_______

# GLOSSARY

## GENERATE NEW TOKENS:
In order to refresh and obtain new tokens for existing users use the commands using the appropriate user name and the enter the MFA code. 

Tips: befure executing the CLI command be sure to have the password ready and the Authenticator app open for that particular user.

For admin users:

```
export USERNAME="adminii.test"

python scripts/mfa_bootstrap.py \
  --username "$USERNAME" \
  --region "$AWS_REGION" \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var ID_TOKEN \
  --write-env Reports/admin_tokens.env

source Reports/admin_tokens.env
```

For test users:

```
export USERNAME="userii.test"

python scripts/mfa_bootstrap.py \
  --username "$USERNAME" \
  --region "$AWS_REGION" \
  --client-id "$COGNITO_APP_CLIENT_ID" \
  --token-var NON_ADMIN_ID_TOKEN \
  --write-env Reports/non_admin_tokens.env

source Reports/non_admin_tokens.env
```

Verify:

Group claims:
```
python -c "import os,json,base64; [print(n,json.loads(base64.urlsafe_b64decode((t:=os.environ[n]).split('.')[1]+'='*(-len(t.split('.')[1])%4))).get('cognito:groups')) for n in ['ID_TOKEN','NON_ADMIN_ID_TOKEN']]"
```

Access-token scopes:
```
python -c "import os,json,base64; [print(n,json.loads(base64.urlsafe_b64decode((t:=os.environ[n]).split('.')[1]+'='*(-len(t.split('.')[1])%4))).get('scope')) for n in ['ACCESS_TOKEN','NON_ADMIN_ACCESS_TOKEN']]"
```


```
echo "Admin ID token length: ${#ID_TOKEN}"
echo "Admin access token length: ${#ACCESS_TOKEN}"
echo "Non-admin ID token length: ${#NON_ADMIN_ID_TOKEN}"
echo "Non-admin access token length: ${#NON_ADMIN_ACCESS_TOKEN}"
```


# Verification Checks:

## Account verification:
confirm an account exists:

```bash
aws cognito-idp admin-get-user \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --region "$AWS_REGION"
```


If necessary, add to a Group:
```bash
aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --group-name user \
  --region "$AWS_REGION"
```


## Group Checks:

List All members of a specific group:
```bash
aws cognito-idp list-users-in-group \
  --user-pool-id "$USER_POOL_ID" \
  --group-name admin \
  --region "$AWS_REGION"
```

Show only usernames:
```bash
aws cognito-idp list-users-in-group \
  --user-pool-id "$USER_POOL_ID" \
  --group-name admin \
  --region "$AWS_REGION" \
  --query 'Users[].Username' \
  --output table
```


List every group:
```bash
aws cognito-idp list-groups \
  --user-pool-id "$USER_POOL_ID" \
  --region "$AWS_REGION" \
  --query 'Groups[].GroupName' \
  --output table
```

List members from both current groups:
```bash
for GROUP in admin user; do
  echo "Group: $GROUP"
  aws cognito-idp list-users-in-group \
    --user-pool-id "$USER_POOL_ID" \
    --group-name "$GROUP" \
    --region "$AWS_REGION" \
    --query 'Users[].Username' \
    --output table
done
```


## SUMMARY - User Creation:

```bash
aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --user-attributes \
    Name=email,Value=userii.test@example.com \
    Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region "$AWS_REGION"

aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --password 'ChangeMe123!' \
  --permanent \
  --region "$AWS_REGION"

aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --group-name user \
  --region "$AWS_REGION"
  ```

  Verify:
  ```bash
  aws cognito-idp admin-list-groups-for-user \
  --user-pool-id "$USER_POOL_ID" \
  --username userii.test \
  --region "$AWS_REGION"
```

then run `mfa_bootstrap.py` afterwards to configure MFA and generate token. Be sure to change password


## To Rerun tests after updating tokens
After generating new tokens and users access is up to date:


Verify the following:

```bash
echo "Admin token length: ${#ID_TOKEN}"
echo "Admin access token length: ${#ACCESS_TOKEN}"
echo "Non-admin token length: ${#NON_ADMIN_ID_TOKEN}"
echo "Non-admin access token length: ${#NON_ADMIN_ACCESS_TOKEN}"
aws sts get-caller-identity
```


## run RBAC bash script:

```bash
source Reports/admin_tokens.env
source Reports/non_admin_tokens.env

export REGION="us-west-2"

printf 'REGION=%s\n' "$REGION"
printf 'ID_TOKEN length=%s\n' "${#ID_TOKEN}"
printf 'ACCESS_TOKEN length=%s\n' "${#ACCESS_TOKEN}"
printf 'NON_ADMIN_ID_TOKEN length=%s\n' "${#NON_ADMIN_ID_TOKEN}"
printf 'NON_ADMIN_ACCESS_TOKEN length=%s\n' "${#NON_ADMIN_ACCESS_TOKEN}"

terraform validate
aws sts get-caller-identity

bash ./scripts/rbac_test.sh
```



## Verify deployed settings for Lambda `get_unused_token_dectector`:
```bash
aws lambda get-function-configuration \
  --function-name unused_token_detector_function \
  --query 'Environment.Variables.{Threshold:UNUSED_TOKEN_THRESHOLD_MINUTES,MaxTokens:SOAR_MAX_OUTPUT_TOKENS,GenerateOnEmpty:SOAR_GENERATE_ON_EMPTY}' \
  --region us-west-2
```

### Asynchronous invocation for `unused_token_detector_function` only:
```bash
aws lambda invoke \
  --function-name unused_token_detector_function \
  --invocation-type Event \
  --payload '{"manual":true,"force_soar":true,"reason":"Operator-requested unused token review"}' \
  --cli-binary-format raw-in-base64-out \
  --region "$REGION" \
  unused-detector-submit.json
  ```


## Reports Bucket

```bash
REPORTS_BUCKET="$(terraform output -raw incident_reports_bucket_name)"

aws s3 sync \
  "s3://$REPORTS_BUCKET/reports/" \
  "Reports/" \
  --region "$REGION"
  ```
