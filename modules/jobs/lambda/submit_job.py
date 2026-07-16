"""POST /jobs — validate entitlement, create the job record, enqueue the message.

Job contract (frozen — see PHASE2.md in the stability_ai repo):
  SQS message body: {"job_id": str, "type": str, "params": dict}
  DynamoDB statuses: queued | running | succeeded | failed | stalled
"""

import json
import os
import time
import uuid

import boto3

dynamodb = boto3.client("dynamodb")
sqs = boto3.client("sqs")

JOBS_TABLE = os.environ["JOBS_TABLE"]
QUEUE_URLS = json.loads(os.environ["QUEUE_URLS"])          # {job_type: queue_url}
GROUP_ENTITLEMENTS = json.loads(os.environ["GROUP_ENTITLEMENTS"])  # {group: [job_type, ...]}
JOB_TTL_DAYS = int(os.environ.get("JOB_TTL_DAYS", "30"))


def _log(level, message, **fields):
    print(json.dumps({"level": level, "message": message, **fields}))


def _parse_groups(claims):
    # cognito:groups arrives in inconsistent formats depending on token type
    # and invocation path: a real list, a comma-separated string, or a
    # bracketed "[admin user]" string. Deliberately defensive — do not
    # simplify (see the SEIR CLAUDE.md sharp-edges list).
    raw = claims.get("cognito:groups", [])
    if isinstance(raw, list):
        return [str(g).strip() for g in raw if str(g).strip()]
    if isinstance(raw, str):
        s = raw.strip()
        if s.startswith("[") and s.endswith("]"):
            s = s[1:-1]
        return [p for p in s.replace(",", " ").split() if p]
    return []


def _caller_identity(event):
    """Returns (username, groups, scopes). M2M (client_credentials) tokens
    carry no cognito:groups — they are mapped to the pseudo-group "m2m" so
    group_entitlements can gate them like any other group."""
    claims = (
        event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    )
    groups = _parse_groups(claims)
    scopes = claims.get("scope", "").split()
    username = claims.get("username") or claims.get("cognito:username") or claims.get("client_id", "")
    if not groups and "rbac-api/user" in scopes:
        groups = ["m2m"]
    return username, groups, scopes


def _entitled_types(groups, scopes):
    if "rbac-api/admin" in scopes or "admin" in groups:
        return set(QUEUE_URLS.keys())
    entitled = set()
    for g in groups:
        entitled.update(GROUP_ENTITLEMENTS.get(g, []))
    return entitled


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def lambda_handler(event, context):
    username, groups, scopes = _caller_identity(event)

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "request body is not valid JSON"})

    job_type = body.get("type")
    params = body.get("params")
    if not job_type or not isinstance(params, dict):
        return _response(400, {"error": "body must be {\"type\": str, \"params\": object}"})

    if job_type not in QUEUE_URLS:
        return _response(400, {"error": f"unknown job type: {job_type}"})

    if job_type not in _entitled_types(groups, scopes):
        _log("warn", "job type not entitled", username=username,
             groups=groups, job_type=job_type)
        return _response(403, {"error": f"not entitled to job type: {job_type}"})

    job_id = str(uuid.uuid4())
    now = int(time.time())
    expires_at = now + JOB_TTL_DAYS * 86400

    dynamodb.put_item(
        TableName=JOBS_TABLE,
        Item={
            "job_id": {"S": job_id},
            "type": {"S": job_type},
            "status": {"S": "queued"},
            "username": {"S": username},
            "created_at": {"N": str(now)},
            "updated_at": {"N": str(now)},
            "expires_at": {"N": str(expires_at)},
        },
        ConditionExpression="attribute_not_exists(job_id)",
    )

    try:
        sqs.send_message(
            QueueUrl=QUEUE_URLS[job_type],
            MessageBody=json.dumps(
                {"job_id": job_id, "type": job_type, "params": params}
            ),
        )
    except Exception as exc:  # enqueue failed — don't leave a phantom queued job
        dynamodb.update_item(
            TableName=JOBS_TABLE,
            Key={"job_id": {"S": job_id}},
            UpdateExpression="SET #s = :failed, #e = :err, updated_at = :now",
            ExpressionAttributeNames={"#s": "status", "#e": "error"},
            ExpressionAttributeValues={
                ":failed": {"S": "failed"},
                ":err": {"S": f"enqueue failed: {exc}"},
                ":now": {"N": str(int(time.time()))},
            },
        )
        _log("error", "enqueue failed", job_id=job_id, job_type=job_type,
             error=str(exc))
        return _response(500, {"error": "failed to enqueue job", "job_id": job_id})

    _log("info", "job submitted", job_id=job_id, job_type=job_type,
         username=username)
    return _response(202, {"job_id": job_id, "status": "queued"})
