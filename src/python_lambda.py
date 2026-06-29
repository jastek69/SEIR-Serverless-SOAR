import json
from datetime import datetime

from token_tracking import mark_token_used


def lambda_handler(event, context):
    print("Incoming event:", json.dumps(event))

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

    if "admin" in groups:
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
