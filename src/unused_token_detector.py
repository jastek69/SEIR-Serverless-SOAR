import json
import os
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Attr


TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
UNUSED_TOKEN_THRESHOLD_MINUTES = int(os.environ.get("UNUSED_TOKEN_THRESHOLD_MINUTES", "5"))
UNUSED_TOKEN_ALERT_TOPIC_ARN = os.environ.get("UNUSED_TOKEN_ALERT_TOPIC_ARN", "")

dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table(TRACKING_TABLE)
sns = boto3.client("sns")


def _parse_iso(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _publish_unused_token_alert(item: dict, age_minutes: int) -> None:
    if not UNUSED_TOKEN_ALERT_TOPIC_ARN:
        return

    message = {
        "event": "unused_token_detected",
        "token_id": item.get("token_id"),
        "username": item.get("username", "unknown-user"),
        "issued_at_iso": item.get("issued_at_iso"),
        "status": item.get("status", "active"),
        "used": item.get("used", False),
        "age_minutes": age_minutes,
        "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
    }

    sns.publish(
        TopicArn=UNUSED_TOKEN_ALERT_TOPIC_ARN,
        Subject="Unused Token Alert",
        Message=json.dumps(message),
    )


def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    threshold = now - timedelta(minutes=UNUSED_TOKEN_THRESHOLD_MINUTES)
    scan_kwargs = {
        "FilterExpression": Attr("used").eq(False) & Attr("status").eq("active"),
    }

    scanned = 0
    alerted = 0

    while True:
        response = tracking.scan(**scan_kwargs)
        items = response.get("Items", [])
        scanned += len(items)

        for item in items:
            issued_raw = item.get("issued_at_iso")
            if not issued_raw:
                continue

            issued_at = _parse_iso(issued_raw)
            if issued_at > threshold:
                continue

            age_minutes = int((now - issued_at).total_seconds() // 60)
            _publish_unused_token_alert(item, age_minutes)
            alerted += 1

        last_key = response.get("LastEvaluatedKey")
        if not last_key:
            break
        scan_kwargs["ExclusiveStartKey"] = last_key

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Unused token scan completed",
                "scanned": scanned,
                "alerted": alerted,
                "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
            }
        ),
    }