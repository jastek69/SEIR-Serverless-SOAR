
import os
import json
import hashlib
import time
from datetime import datetime, timezone
import boto3

from botocore.exceptions import ClientError

# =========================
# Configuration
# =========================
dynamodb = boto3.resource("dynamodb")

# DynamoDB tables for tracking tokens and revocations so real token values remain secure and only hashes are stored for validation.
# This allows us to track token usage and revoke tokens without exposing raw token values.
TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
REVOCATION_TABLE = os.environ.get("REVOCATION_TABLE", "revocation-table")

tracking = dynamodb.Table(TRACKING_TABLE)
revocations = dynamodb.Table(REVOCATION_TABLE)


def _utc_iso_now():
    return datetime.now(timezone.utc).isoformat()

def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()

def lambda_handler(event, context):
    body = event.get("body")
    payload = json.loads(body) if isinstance(body, str) else (body or {})

    token_id = payload.get("token_id")
    raw_token = payload.get("token")
    action = payload.get("action", "used")
    reason = payload.get("reason", "manual")

    if not token_id and not raw_token:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Provide token_id or token"}),
        }

    token_hash = _sha256_hex(raw_token) if raw_token else None
    now_iso = _utc_iso_now()
    now_epoch = int(time.time())

    if token_id:
        new_status = "revoked" if action == "revoke" else "used"
        tracking.update_item(
            Key={"token_id": token_id},
            UpdateExpression="SET #s = :s, used = :u, updated_at_iso = :t",
            ConditionExpression="attribute_exists(token_id)",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":s": new_status,
                ":u": (action != "revoke"),
                ":t": now_iso,
            },
        )
     # Set revocation to expire after 300S (5 minutes) to prevent indefinite growth of the revocation table
    if action == "revoke" and token_hash:
        expires_at = now_epoch + 300 
        revocations.put_item(
            Item={
                "token_hash": token_hash,
                "expires_at": expires_at,
                "revoked_at_iso": now_iso,
                "reason": reason,
            }
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "token updated", "action": action}),
    }
