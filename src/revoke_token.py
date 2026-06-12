
import os
import json
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Attr


TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
CLEANUP_AGE_MINUTES = int(os.environ.get("TOKEN_CLEANUP_AGE_MINUTES", "10"))

dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table(TRACKING_TABLE)


def _parse_issued_at(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _delete_stale_unused_tokens(cutoff: datetime) -> int:
    deleted_count = 0
    scan_kwargs = {
        "FilterExpression": Attr("used").eq(False) & Attr("status").eq("active"),
    }

    while True:
        response = tracking.scan(**scan_kwargs)

        for item in response.get("Items", []):
            issued_at_iso = item.get("issued_at_iso")
            token_id = item.get("token_id")
            if not issued_at_iso or not token_id:
                continue

            issued_at = _parse_issued_at(issued_at_iso)
            if issued_at > cutoff:
                continue

            tracking.delete_item(
                Key={"token_id": token_id},
                ConditionExpression="attribute_exists(token_id)",
            )
            deleted_count += 1
            print(f"Deleted stale unused token for user {item.get('username', 'unknown-user')}: {token_id}")

        last_evaluated_key = response.get("LastEvaluatedKey")
        if not last_evaluated_key:
            return deleted_count

        scan_kwargs["ExclusiveStartKey"] = last_evaluated_key


def lambda_handler(event, context):
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=CLEANUP_AGE_MINUTES)
    deleted_count = _delete_stale_unused_tokens(cutoff)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Unused token cleanup completed",
                "deleted_count": deleted_count,
                "cleanup_age_minutes": CLEANUP_AGE_MINUTES,
            }
        ),
    }
