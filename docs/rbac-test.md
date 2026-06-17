# End-to-End RBAC Test Runbook

Use this runbook to validate Cognito authentication, RBAC allow/deny behavior, WAF protection, and supporting AWS resources.

## Overall Flow

1. Create Cognito users and groups.
2. Ensure app client settings and environment variables are correct.
3. Get the admin tokens and export `ID_TOKEN` and `ACCESS_TOKEN`.
4. Get the non-admin tokens and export `NON_ADMIN_ID_TOKEN` and `NON_ADMIN_ACCESS_TOKEN`.
5. Run scripted and manual tests.
6. Verify logs, DynamoDB writes, and scheduler status.

## 1. Create Cognito users and groups

Create at least one admin user and one non-admin user in the user pool used by API auth.

```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export ADMIN_POOL_ID="$(terraform output -raw cognito_admin_user_pool_id)"

echo "$USER_POOL_ID"
echo "$ADMIN_POOL_ID"

aws cognito-idp create-group --user-pool-id "$USER_POOL_ID" --group-name admin --region "$AWS_REGION"
aws cognito-idp create-group --user-pool-id "$USER_POOL_ID" --group-name user --region "$AWS_REGION"

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

- Both users exist and are enabled.
- `admin.test` is in the `admin` group.
- `user.test` is in the `user` group.

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
- The exported `ID_TOKEN_TRACKING_ID` lets `rbac_test.sh` mark that same JWT record as used after authenticated API calls.

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

Repeat for `user.test`:

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
- With API Gateway `authorization_scopes` enabled, API calls must use `ACCESS_TOKEN`, not `ID_TOKEN`.

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

## 4. Get non-admin token

Preferred path:

```bash
python scripts/mfa_bootstrap.py \
  --username user.test \
  --region us-west-2 \
  --auto-totp \
  --token-var NON_ADMIN_ID_TOKEN \
  --write-env Reports/non_admin_tokens.env

source Reports/non_admin_tokens.env
```

Expected results:

- `Reports/non_admin_tokens.env` is created.
- `NON_ADMIN_ID_TOKEN` and `NON_ADMIN_ACCESS_TOKEN` are non-empty after sourcing the file.
- `NON_ADMIN_ACCESS_TOKEN` is used for API Gateway scope-deny testing.

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

Expected results:

- `403` for both non-admin requests.
- `200` for both admin requests.
- If admin returns `403`, decode `ACCESS_TOKEN` and confirm it contains the required `rbac-api/admin` scope.

### Capture logs

```bash
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"

echo "PY_LOG_GROUP=$PY_LOG_GROUP"
echo "NODE_LOG_GROUP=$NODE_LOG_GROUP"

export MSYS_NO_PATHCONV=1
aws logs tail "$PY_LOG_GROUP" --region us-west-2 --since 5m
aws logs tail "$NODE_LOG_GROUP" --region us-west-2 --since 5m
```

Note: `MSYS_NO_PATHCONV` disables Git Bash path conversion.

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

```bash
source Reports/admin_tokens.env
source Reports/non_admin_tokens.env

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

### 5.5 RBAC deny-path test (non-admin token)

```bash
curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ACCESS_TOKEN"
```

Expected: `403`.

With API Gateway `authorization_scopes`, this deny can happen before Lambda runs if the non-admin access token does not contain `rbac-api/admin`. If API Gateway allows the request through, Lambda still performs the final group-based RBAC check.

If you get `401` with `The incoming token has expired`, refresh the non-admin token and rerun:

```bash
python scripts/mfa_bootstrap.py \
  --username user.test \
  --region us-west-2 \
  --token-var NON_ADMIN_ID_TOKEN \
  --write-env Reports/non_admin_tokens.env

source Reports/non_admin_tokens.env
```

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

aws dynamodb describe-table --table-name token-revocation --region us-west-2
aws dynamodb scan --table-name token-revocation --max-items 20 --region us-west-2
```

Optional token-hash lookup:

```bash
aws dynamodb query --table-name token-tracking --index-name token-hash-index --key-condition-expression "token_hash = :h" --expression-attribute-values '{":h":{"S":"replace_with_hash"}}' --region us-west-2
```

### 5.8 Direct Lambda invocation checks

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
