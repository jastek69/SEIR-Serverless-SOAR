import copy
import json
from datetime import datetime

from token_tracking import mark_token_used


def redact_event_for_logging(event):
    """Return a copy of the event with bearer tokens redacted — safe to
    log. Never log the real event: API Gateway proxy events carry the
    caller's live Authorization header in both headers and
    multiValueHeaders, and Lambda's own request/response logging is
    plaintext in CloudWatch for however long the log group retains it."""

    redacted = copy.deepcopy(event)

    for header_key in ("headers", "multiValueHeaders"):
        headers = redacted.get(header_key)
        if isinstance(headers, dict):
            for name in list(headers.keys()):
                if name.lower() == "authorization":
                    headers[name] = "[REDACTED]"

    return redacted


def lambda_handler(event, context):
    print("Incoming event:", json.dumps(redact_event_for_logging(event)))

    # queryStringParameters can be null in API Gateway proxy events.
    query_params = event.get("queryStringParameters") or {}
    name = query_params.get("name", "Unknown")

    response = {
        "message": f"Hello {name} from Python!",
        "timestamp": datetime.utcnow().isoformat(),
    }

    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    raw_groups = claims.get("cognito:groups", [])
    if isinstance(raw_groups, str):
        groups = [g.strip() for g in raw_groups.split(",") if g.strip()]
    elif isinstance(raw_groups, list):
        groups = raw_groups
    else:
        groups = []

    scopes = claims.get("scope", "").split()
    is_admin = "admin" in groups or "rbac-api/admin" in scopes

    if is_admin:
        response["role"] = "admin"
    else:
        return {
            "statusCode": 403,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Access denied: admin group required"}),
        }

    matched_token_id = mark_token_used(
        claims,
        getattr(context, "aws_request_id", None),
    )
    if matched_token_id:
        response["token_tracking_id"] = matched_token_id
    
    print("Response:", json.dumps(response))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response),
    }
