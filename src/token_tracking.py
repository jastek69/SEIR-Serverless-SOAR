import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table(TRACKING_TABLE)


def utc_iso_now():
    return datetime.now(timezone.utc).isoformat()


def mark_token_used(claims, request_id):
    token_ids = []
    for key in ("jti", "origin_jti"):
        value = claims.get(key)
        if value and value not in token_ids:
            token_ids.append(value)

    if not token_ids:
        return None

    for token_id in token_ids:
        try:
            tracking.update_item(
                Key={"token_id": token_id},
                UpdateExpression="SET #s = :s, used = :u, updated_at_iso = :t, last_used_request_id = :r",
                ConditionExpression="attribute_exists(token_id)",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={
                    ":s": "used",
                    ":u": True,
                    ":t": utc_iso_now(),
                    ":r": request_id or "unknown-request",
                },
            )
            return token_id
        except ClientError as exc:
            error_code = exc.response.get("Error", {}).get("Code", "")
            if error_code != "ConditionalCheckFailedException":
                raise

    return None