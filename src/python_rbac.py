import json
from token_tracking import mark_token_used

def lambda_handler(event, context):
    claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    raw_groups = claims.get("cognito:groups", [])
    if isinstance(raw_groups, str):
        groups = [g.strip() for g in raw_groups.split(",") if g.strip()]
    elif isinstance(raw_groups, list):
        groups = raw_groups
    else:
        groups = []

    scopes = claims.get("scope", "").split()
    is_admin = "admin" in groups or "rbac-api/admin" in scopes

    # RBAC logic: reports whether the supplied token's claims grant admin
    # access, regardless of resource path, since this function is invoked
    # directly to test token/group/scope handling rather than through API Gateway.
    if not is_admin:
        return {
            "statusCode": 403,
            "body": json.dumps({
                "error": "Access denied",
                "groups": groups,
                "scopes": scopes,
            })
        }

    matched_token_id = mark_token_used(
        claims,
        getattr(context, "aws_request_id", None),
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Access granted",
            "groups": groups,
            "scopes": scopes,
            "token_tracking_id": matched_token_id,
        })
    }