# End-to-End RBAC Test Runbook

Use this runbook to validate Cognito authentication, RBAC allow/deny behavior, WAF protection, and supporting AWS resources.

## Overall Flow

1. Create Cognito users and groups.
2. Ensure app client settings and environment variables are correct.
3. Get admin token and export ID_TOKEN and ACCESS_TOKEN.
4. Get non-admin token and export NON_ADMIN_ID_TOKEN.
5. Run scripted/manual tests.
6. Verify logs, DynamoDB writes, and scheduler status.

## 1. Create Cognito users and groups

Create at least one admin user and one non-admin user in the user pool used by API auth.

```bash
export AWS_REGION="us-west-2"
export USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)"
export ADMIN_POOL_ID="$(terraform output -raw cognito_admin_user_pool_id)"

# Optional: verify pool IDs are set
echo "$USER_POOL_ID"
echo "$ADMIN_POOL_ID"

# Create groups in the user pool used by API auth
aws cognito-idp create-group --user-pool-id "$USER_POOL_ID" --group-name admin --region "$AWS_REGION"
aws cognito-idp create-group --user-pool-id "$USER_POOL_ID" --group-name user --region "$AWS_REGION"

# Create users (change emails/usernames as needed)
aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username admin.test --user-attributes Name=email,Value=admin.test@example.com Name=email_verified,Value=true --message-action SUPPRESS --region "$AWS_REGION"
aws cognito-idp admin-create-user --user-pool-id "$USER_POOL_ID" --username user.test --user-attributes Name=email,Value=user.test@example.com Name=email_verified,Value=true --message-action SUPPRESS --region "$AWS_REGION"

# Set permanent passwords so accounts can authenticate immediately
aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" --username admin.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"
aws cognito-idp admin-set-user-password --user-pool-id "$USER_POOL_ID" --username user.test --password 'ChangeMe123!' --permanent --region "$AWS_REGION"

# Assign group membership
aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" --username admin.test --group-name admin --region "$AWS_REGION"
aws cognito-idp admin-add-user-to-group --user-pool-id "$USER_POOL_ID" --username user.test --group-name user --region "$AWS_REGION"

# Verify group membership
aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username admin.test --region "$AWS_REGION"
aws cognito-idp admin-list-groups-for-user --user-pool-id "$USER_POOL_ID" --username user.test --region "$AWS_REGION"
```

Expected results:

- Both users exist and are enabled.
- `admin.test` is in the `admin` group.
- `user.test` is in the `user` group.

## 2. Ensure app client is correct

- Use a Cognito app client with no client secret for USER_PASSWORD_AUTH.
- Set required environment variables:

```bash
export AWS_REGION="us-west-2"
export COGNITO_APP_CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
```

Expected results:

- Variables are set in the current shell.

## 3. Get admin tokens

Primary path: use the MFA bootstrap helper.

### 3.0 Preferred token bootstrap with mfa_bootstrap.py (admin user)

```bash
python scripts/mfa_bootstrap.py \
	--username admin.test \
	--region us-west-2 \
	--token-var ID_TOKEN \
	--write-env Reports/admin_tokens.env

source Reports/admin_tokens.env
```

Notes:
- If the password contains `!` or other shell-sensitive characters, omit `--password` and enter it at the secure prompt.
- The script handles MFA setup, prompts for the TOTP code, and writes a `source`-able env file.

Expected results:
- `Reports/admin_tokens.env` is created.
- `ID_TOKEN` and `ACCESS_TOKEN` load successfully after `source Reports/admin_tokens.env`.

### 3.1 Manual one-time MFA bootstrap (admin user, fallback)

```bash
export AWS_REGION="us-west-2"
export CLIENT_ID="$(terraform output -raw cognito_user_pool_client_id)"
export USERNAME="admin.test"
export PASSWORD="ChangeMe123!"

# Step 1: start auth and capture MFA_SETUP session
SESSION=$(aws cognito-idp initiate-auth --client-id "$CLIENT_ID" --auth-flow USER_PASSWORD_AUTH --auth-parameters "USERNAME=$USERNAME,PASSWORD=$PASSWORD" --region "$AWS_REGION" --query Session --output text)
echo "$SESSION"

# Step 2: get TOTP secret and follow-up session
read SECRET_CODE MFA_SETUP_SESSION <<< "$(aws cognito-idp associate-software-token --session "$SESSION" --region "$AWS_REGION" --query '[SecretCode,Session]' --output text)"
echo "TOTP secret: $SECRET_CODE"

# Add SECRET_CODE to Google Authenticator/Authy as a manual key.
# Then enter the current 6-digit code.
read -p "Enter current 6-digit TOTP code: " TOTP_CODE

# Step 3: verify TOTP and capture verify session
VERIFY_SESSION=$(aws cognito-idp verify-software-token --session "$MFA_SETUP_SESSION" --user-code "$TOTP_CODE" --friendly-device-name "admin-test-device" --region "$AWS_REGION" --query Session --output text)
echo "$VERIFY_SESSION"

# Step 4: complete MFA_SETUP challenge and get tokens
read ID_TOKEN ACCESS_TOKEN REFRESH_TOKEN <<< "$(aws cognito-idp respond-to-auth-challenge --client-id "$CLIENT_ID" --challenge-name MFA_SETUP --session "$VERIFY_SESSION" --challenge-responses "USERNAME=$USERNAME" --region "$AWS_REGION" --query 'AuthenticationResult.[IdToken,AccessToken,RefreshToken]' --output text)"

export ID_TOKEN
export ACCESS_TOKEN
echo "ID_TOKEN length: ${#ID_TOKEN}"
echo "ACCESS_TOKEN length: ${#ACCESS_TOKEN}"
```

Repeat the same manual bootstrap for non-admin if needed:
- set `USERNAME="user.test"`
- set that user's password in `PASSWORD`
- after Step 4, export non-admin token: `export NON_ADMIN_ID_TOKEN="$ID_TOKEN"`

## 4. Get non-admin token

Preferred path:

```bash
python scripts/mfa_bootstrap.py \
	--username user.test \
	--region us-west-2 \
	--token-var NON_ADMIN_ID_TOKEN \
	--write-env Reports/non_admin_tokens.env

source Reports/non_admin_tokens.env
```

Expected results:

- `Reports/non_admin_tokens.env` is created.
- `NON_ADMIN_ID_TOKEN` is non-empty after sourcing the file.

## 5. Run tests

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

### 5.2 Set convenience variables

```bash
export API_PY_BASE="$(terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(terraform output -raw api_node_invoke_url)"
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"
export SCHEDULE_NAME="$(terraform output -raw unused_token_schedule_name)"
```

### 5.3 Negative auth test (no token)

```bash
curl -i "$API_PY_BASE/PythonResource"
curl -i "$API_NODE_BASE/NodeResource"
```

Expected: `401 Unauthorized`.

### 5.4 Positive auth test (admin token)

```bash
curl -i "$API_PY_BASE/PythonResource?name=theo" -H "Authorization: $ID_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=theo" -H "Authorization: $ID_TOKEN"
```

Expected: `200 OK` for admin group membership.

### 5.5 RBAC deny-path test (non-admin token)

```bash
curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ID_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ID_TOKEN"
```

Expected: `403` with `Access denied: admin group required`.

If you get `401` with `The incoming token has expired`, refresh the non-admin token and rerun:

```bash
python scripts/mfa_bootstrap.py \
	--username user.test \
	--region us-west-2 \
	--token-var NON_ADMIN_ID_TOKEN \
	--write-env Reports/non_admin_tokens.env

source Reports/non_admin_tokens.env
```

### 5.6 WAF tests (strict + informational)

Run strict block payloads first. These should return `403 Forbidden` when WAF is enforcing block mode.

```bash
curl -i "$API_PY_BASE/PythonResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ID_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $ID_TOKEN"
```

Expected strict results:

- HTTP `403` with API Gateway `Forbidden` response body.
- API Gateway access logs show `wafResponseCode: WAF_BLOCK` and `wafStatus: 403`.

Run SQLi-style payloads as informational checks. These may be `200` or `403` depending on current managed rule coverage and sensitivity.

```bash
curl -i "$API_PY_BASE/PythonResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $ID_TOKEN"
curl -i "$API_NODE_BASE/NodeResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $ID_TOKEN"
```

Expected informational results:

- `403` is acceptable and indicates stronger blocking.
- `200` is acceptable if logs still show WAF evaluated and allowed (`wafResponseCode: WAF_ALLOW`).
- Treat `200` here as signal to tune WAF rules, not as RBAC/API regression.

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

The script now writes a Markdown summary document to the Reports directory:

```bash
Reports/rbac_test_summary.md
```

This summary includes:

- Strict WAF XSS block result (`PASS`/`FAIL`) with Python and Node HTTP statuses.
- Informational SQLi-style WAF statuses for both APIs.
- DynamoDB tables show expected writes for token tracking/revocation flows.
- Scheduler exists and detector invocation succeeds.
- CloudWatch/API/WAF logs show corresponding request records.

## Notes

- `scripts/mfa_bootstrap.py` is the preferred token path for first-time MFA users.
- Account selection is determined by the username/password you provide for the bootstrap helper or Cognito auth flow.
- Run token retrieval once per user type: admin first, non-admin second.
- Token env files under `Reports/` are local artifacts and should not be committed.
