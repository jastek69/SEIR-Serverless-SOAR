#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off
# Git Bash can rewrite '/aws/...' arguments into Windows paths. Disable that conversion
# so CloudWatch log group names remain valid for AWS CLI commands.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"


export API_PY_BASE="$(terraform output -raw api_python_invoke_url)"
export API_NODE_BASE="$(terraform output -raw api_node_invoke_url)"
export PY_LOG_GROUP="$(terraform output -raw python_lambda_log_group)"
export NODE_LOG_GROUP="$(terraform output -raw node_lambda_log_group)"
export SCHEDULE_NAME="$(terraform output -raw unused_token_schedule_name)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPORTS_DIR="${REPORTS_DIR:-$REPO_ROOT/Reports}"
REGION="${REGION:-us-west-2}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
FOLLOW_LOGS="${FOLLOW_LOGS:-false}"
RUN_TOKEN_PRIMER="${RUN_TOKEN_PRIMER:-false}"
TOKEN_PRIMER_SCRIPT="${TOKEN_PRIMER_SCRIPT:-$REPO_ROOT/src/easier_get_token.py}"
REPORT_FILE="${REPORT_FILE:-$REPORTS_DIR/rbac_test_summary.md}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    if command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    else
        echo "ERROR: python interpreter not found. Set PYTHON_BIN to a valid executable." >&2
        exit 1
    fi
fi

token_is_fresh() {
    local token="$1"
    "$PYTHON_BIN" - "$token" <<'PY'
import base64
import json
import sys
import time

token = sys.argv[1]
parts = token.split(".")
if len(parts) < 2:
    sys.exit(2)

payload = parts[1] + ("=" * (-len(parts[1]) % 4))
try:
    claims = json.loads(base64.urlsafe_b64decode(payload.encode("ascii")).decode("utf-8"))
except Exception:
    sys.exit(2)

exp = claims.get("exp")
if not isinstance(exp, (int, float)):
    sys.exit(2)

# Keep a small safety margin so near-expiry tokens don't fail mid-test.
sys.exit(0 if exp > time.time() + 30 else 1)
PY
}

run_curl_with_status() {
    local out_var_name="$1"
    shift

    local response=""
    local status=""
    response="$(curl -sS -i "$@")"
    printf "%s\n" "$response"
    status="$(printf "%s\n" "$response" | awk '/^HTTP\/[0-9.]+ [0-9]+/{code=$2} END{print code}')"
    printf -v "$out_var_name" '%s' "$status"
}

mkdir -p "$REPORTS_DIR"
{
    echo "# RBAC and WAF Test Summary"
    echo
    echo "- Generated (UTC): $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "- Region: $REGION"
    echo "- Python API: $API_PY_BASE"
    echo "- Node API: $API_NODE_BASE"
    echo
} > "$REPORT_FILE"

if [[ "$FOLLOW_LOGS" == "true" ]]; then
    LOG_TAIL_ARGS=(--since 15m --follow)
else
    LOG_TAIL_ARGS=(--since 15m)
fi

if command -v cygpath >/dev/null 2>&1; then
    TOKEN_PRIMER_SCRIPT_NATIVE="$(cygpath -w "$TOKEN_PRIMER_SCRIPT")"
else
    TOKEN_PRIMER_SCRIPT_NATIVE="$TOKEN_PRIMER_SCRIPT"
fi

# Optional token primer helper. Keep this off by default because most test runs
# already source tokens from Reports/*.env.
if [[ "$RUN_TOKEN_PRIMER" == "true" ]]; then
    echo "Running token primer script: $TOKEN_PRIMER_SCRIPT"
    "$PYTHON_BIN" "$TOKEN_PRIMER_SCRIPT_NATIVE"
fi

if [[ -z "${ID_TOKEN:-}" || -z "${ACCESS_TOKEN:-}" ]]; then
    echo "ID_TOKEN/ACCESS_TOKEN not pre-set; API auth tests will be skipped."
    echo "Set ID_TOKEN and ACCESS_TOKEN in your shell to run positive/RBAC/WAF auth checks."
else
    if token_is_fresh "$ID_TOKEN"; then
        VALID_ID_TOKEN="$ID_TOKEN"
        VALID_ACCESS_TOKEN="$ACCESS_TOKEN"
    else
        echo "ID_TOKEN appears expired or invalid; skipping auth-required API tests."
        echo "Refresh with: python scripts/mfa_bootstrap.py --username admin.test --region $REGION --token-var ID_TOKEN --write-env Reports/admin_tokens.env"
        unset VALID_ID_TOKEN
    fi
fi

NON_ADMIN_ID_TOKEN="${NON_ADMIN_ID_TOKEN:-}"
if [[ -n "$NON_ADMIN_ID_TOKEN" ]] && ! token_is_fresh "$NON_ADMIN_ID_TOKEN"; then
    echo "NON_ADMIN_ID_TOKEN appears expired or invalid; skipping RBAC deny test."
    echo "Refresh with: python scripts/mfa_bootstrap.py --username user.test --region $REGION --token-var NON_ADMIN_ID_TOKEN --write-env Reports/non_admin_tokens.env"
    NON_ADMIN_ID_TOKEN=""
fi

# Example of invoking the Python Lambda function directly for testing purposes, passing the tokens as environment variables. This can be useful for local testing or debugging without waiting for the scheduled EventBridge rule to trigger the Lambda function.
echo "Invoking Python Lambda function directly for testing..."
aws lambda invoke \
    --function-name "python_lambda_function" \
    --payload '{}' \
    --region "$REGION" \
    --cli-binary-format raw-in-base64-out \
    response.json
echo "Lambda function invoked. Response saved to response.json."


# Invoking Node Lambda function directly for testing purposes, passing the tokens as environment variables.
echo "Invoking Node Lambda function directly for testing..."
aws lambda invoke \
    --function-name "node_lambda_function" \
    --payload '{}' \
    --region "$REGION" \
    --cli-binary-format raw-in-base64-out \
    node_response.json
echo "Node Lambda function invoked. Response saved to node_response.json."

# Negative test: invoking Lambda with invalid tokens to ensure proper error handling and report generation for failed authentication scenarios
echo "Invoking Python Lambda function with invalid tokens for negative testing..."
aws lambda invoke \
    --function-name "python_lambda_function" \
    --payload '{}' \
    --region "$REGION" \
    --cli-binary-format raw-in-base64-out \
    invalid_response.json
echo "Python Lambda function invoked with invalid tokens. Response saved to invalid_response.json."

echo "Testing script execution completed. Check the generated reports in $REPORTS_DIR and the Lambda responses in response.json, node_response.json, and invalid_response.json for results."    


# RBAC deny testing using a dedicated non-admin token variable. This allows for more explicit testing of RBAC scenarios without relying on the validity of the main ID_TOKEN, which may have admin privileges.
# Setting NON_ADMIN_ID_TOKEN to a valid token from a non-admin user will directly test the RBAC deny path and ensure that it returns the expected 403 Forbidden response when accessing protected resources.
# If NON_ADMIN_ID_TOKEN is not set, the script will skip the RBAC deny test and provide a message indicating how to enable it.
echo "testing Negative auth scenario with Node Lambda function..."
curl -i "$API_PY_BASE/PythonResource"
curl -i "$API_NODE_BASE/NodeResource"

if [[ -n "${ID_TOKEN:-}" ]]; then
    echo "Positive auth test (valid token)"
    curl -i "$API_PY_BASE/PythonResource?name=theo" -H "Authorization: $VALID_ID_TOKEN"
    curl -i "$API_NODE_BASE/NodeResource?name=theo" -H "Authorization: $VALID_ID_TOKEN"

    if [[ -n "$NON_ADMIN_ID_TOKEN" ]]; then
        echo "RBAC deny test with non-admin token (expected: 403)"
        curl -i "$API_PY_BASE/PythonResource?name=denied" -H "Authorization: $NON_ADMIN_ID_TOKEN"
        curl -i "$API_NODE_BASE/NodeResource?name=denied" -H "Authorization: $NON_ADMIN_ID_TOKEN"
    else
        echo "Skipping RBAC deny test. Set NON_ADMIN_ID_TOKEN to run explicit non-admin checks."
    fi

    echo "WAF strict block test (XSS payload) - expected: 403 / WAF_BLOCK"
    run_curl_with_status PY_WAF_XSS_STATUS "$API_PY_BASE/PythonResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $VALID_ID_TOKEN"
    run_curl_with_status NODE_WAF_XSS_STATUS "$API_NODE_BASE/NodeResource?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" -H "Authorization: $VALID_ID_TOKEN"

    STRICT_WAF_RESULT="PASS"
    if [[ "$PY_WAF_XSS_STATUS" != "403" || "$NODE_WAF_XSS_STATUS" != "403" ]]; then
        STRICT_WAF_RESULT="FAIL"
    fi

    echo "Strict WAF summary: Python=$PY_WAF_XSS_STATUS Node=$NODE_WAF_XSS_STATUS Result=$STRICT_WAF_RESULT"
    {
        echo "## WAF Strict Block Result"
        echo
        echo "- Python XSS status: $PY_WAF_XSS_STATUS"
        echo "- Node XSS status: $NODE_WAF_XSS_STATUS"
        echo "- Result: $STRICT_WAF_RESULT"
        echo
    } >> "$REPORT_FILE"

    echo "WAF informational SQLi-style test - expected: 403 or 200 depending on managed rules"
    run_curl_with_status PY_WAF_SQLI_STATUS "$API_PY_BASE/PythonResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $VALID_ID_TOKEN"
    run_curl_with_status NODE_WAF_SQLI_STATUS "$API_NODE_BASE/NodeResource?name=taaops%27%20OR%20%271%27%3D%271" -H "Authorization: $VALID_ID_TOKEN"

    {
        echo "## WAF Informational SQLi-style Result"
        echo
        echo "- Python SQLi-style status: $PY_WAF_SQLI_STATUS"
        echo "- Node SQLi-style status: $NODE_WAF_SQLI_STATUS"
        echo "- Interpretation: 403 indicates blocked; 200 indicates allowed by current managed rules."
        echo
    } >> "$REPORT_FILE"
else
    echo "Skipping auth-required API tests because ID_TOKEN is not set."
fi

# DynamoDB Tables
echo "Querying main DynamoDB table for entries related to example_user_id..."
aws dynamodb describe-table --table-name token-tracking --region "$REGION"
aws dynamodb scan --table-name token-tracking --region "$REGION" --limit 5

# DynamoDB token-revocation table checks
echo "Checking token-revocation DynamoDB table for any revoked tokens..."
aws dynamodb describe-table --table-name token-revocation --region "$REGION"
aws dynamodb scan --table-name token-revocation --max-items 20 --region "$REGION"

# EventBridge Scheduler checks
echo "Checking EventBridge Scheduler for the presence of the scheduled rule that processes tokens..."
aws scheduler list-schedules --region "$REGION" --query "Schedules[?Name=='$(terraform output -raw unused_token_schedule_name)']"
aws scheduler get-schedule --name "$(terraform output -raw unused_token_schedule_name)" --group-name default --region "$REGION"

# Cloudwatch Logs checks
echo "Checking CloudWatch Logs for recent entries in the Python Lambda log group..."
aws logs tail "$PY_LOG_GROUP" --region "$REGION" "${LOG_TAIL_ARGS[@]}"
aws logs tail "$NODE_LOG_GROUP" --region "$REGION" "${LOG_TAIL_ARGS[@]}"

echo "Checking API Gateway access logs..."

aws logs tail "$(terraform output -raw python_api_gateway_access_log_group)" --region "$REGION" "${LOG_TAIL_ARGS[@]}"
aws logs tail "$(terraform output -raw node_api_gateway_access_log_group)" --region "$REGION" "${LOG_TAIL_ARGS[@]}"

# S3 Logs
WAF_LOGS_BUCKET="$(terraform output -raw waf_logs_bucket)"
if [[ "$WAF_LOGS_BUCKET" != "N/A" ]]; then
    aws s3 ls "s3://$WAF_LOGS_BUCKET" --recursive --region "$REGION"
else
    echo "Skipping WAF S3 logs check because waf_logs_bucket output is N/A."
fi

# WAF logs are in CloudWatch: Depending on the WAF logging configuration, logs may be sent to CloudWatch Logs instead of S3. If that's the case, you can check the WAF log group for recent entries as well.
WAF_LOG_GROUP="$(terraform output -raw waf_log_group)"
if [[ "$WAF_LOG_GROUP" != "N/A" ]]; then
    aws logs tail "$WAF_LOG_GROUP" --region "$REGION" "${LOG_TAIL_ARGS[@]}"
else
    echo "Skipping WAF CloudWatch logs check because waf_log_group output is N/A."
fi

echo "Wrote summary document: $REPORT_FILE"