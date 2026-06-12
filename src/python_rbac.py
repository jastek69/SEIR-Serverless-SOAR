import json

def lambda_handler(event, context):
    claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    raw_groups = claims.get("cognito:groups", [])
    if isinstance(raw_groups, str):
        groups = [g.strip() for g in raw_groups.split(",") if g.strip()]
    elif isinstance(raw_groups, list):
        groups = raw_groups
    else:
        groups = []

    path = event.get("resource")

    # RBAC logic
    if path == "/node" and "admin" not in groups:
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Access denied"})
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Access granted",
            "groups": groups
        })
    }