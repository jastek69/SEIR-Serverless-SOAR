
import os
import json
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError


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
        # Accept legacy records written with uppercase Status while they age out.
        "FilterExpression": Attr("used").eq(False)
        & (Attr("status").eq("active") | Attr("Status").eq("active")),
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


def _delete_token_ids(token_ids: list) -> int:
    deleted_count = 0
    for token_id in token_ids:
        try:
            tracking.delete_item(
                Key={"token_id": token_id},
                ConditionExpression="attribute_exists(token_id)",
            )
            deleted_count += 1
        except ClientError as exc:
            if exc.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
    return deleted_count


def lambda_handler(event, context):
    event = event if isinstance(event, dict) else {}
    token_ids = event.get("token_ids")

    # Targeted mode: delete exactly the rows the caller (e.g. unused_token_detector)
    # already scanned, alerted on, and reported - avoids racing an independent
    # age-based scan against the detector's own alert threshold.
    if token_ids:
        deleted_count = _delete_token_ids(token_ids)
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Targeted unused token cleanup completed",
                    "deleted_count": deleted_count,
                    "requested": len(token_ids),
                }
            ),
        }

    # Standalone mode: independent age-based scan, for manual/direct invokes.
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
