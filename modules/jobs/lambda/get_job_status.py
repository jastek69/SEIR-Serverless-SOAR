"""GET /jobs/{job_id} — return status for the caller's own job.

Other users' jobs return 404, not 403 — deliberately indistinguishable from
"does not exist" so job IDs can't be probed for existence. Admins (group or
rbac-api/admin scope) can read any job.
"""

import json
import os

import boto3

dynamodb = boto3.client("dynamodb")

JOBS_TABLE = os.environ["JOBS_TABLE"]


def _log(level, message, **fields):
    print(json.dumps({"level": level, "message": message, **fields}))


def _parse_groups(claims):
    # Deliberately defensive — see submit_job.py. Do not simplify.
    raw = claims.get("cognito:groups", [])
    if isinstance(raw, list):
        return [str(g).strip() for g in raw if str(g).strip()]
    if isinstance(raw, str):
        s = raw.strip()
        if s.startswith("[") and s.endswith("]"):
            s = s[1:-1]
        return [p for p in s.replace(",", " ").split() if p]
    return []


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def lambda_handler(event, context):
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    groups = _parse_groups(claims)
    scopes = claims.get("scope", "").split()
    username = claims.get("username") or claims.get("cognito:username") or claims.get("client_id", "")
    is_admin = "admin" in groups or "rbac-api/admin" in scopes

    job_id = (event.get("pathParameters") or {}).get("job_id", "")
    if not job_id:
        return _response(400, {"error": "job_id path parameter is required"})

    item = dynamodb.get_item(
        TableName=JOBS_TABLE, Key={"job_id": {"S": job_id}}
    ).get("Item")

    # 404 for both "missing" and "not yours" — intentional, do not change to 403.
    if not item or (not is_admin and item.get("username", {}).get("S") != username):
        return _response(404, {"error": "job not found"})

    body = {
        "job_id": job_id,
        "type": item["type"]["S"],
        "status": item["status"]["S"],
        "created_at": int(item["created_at"]["N"]),
        "updated_at": int(item["updated_at"]["N"]),
    }
    for optional in ("result_prefix", "error"):
        if optional in item:
            body[optional] = item[optional]["S"]
    if "metrics" in item:
        body["metrics"] = json.loads(item["metrics"]["S"])

    return _response(200, body)
