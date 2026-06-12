"""Immediate revoke contract for EventBridge or Bedrock.

This handler accepts either:
- a direct JSON payload from Bedrock or a Bedrock Agent action group
- an EventBridge event with the revoke payload in ``detail``

It normalizes both shapes into one internal request contract and writes the
revocation state into DynamoDB.
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import boto3
from boto3.dynamodb.conditions import Key


CONTRACT = {
	"sources": ["bedrock", "eventbridge"],
	"purpose": "immediate_revoke",
	"required": ["token_hash", "reason"],
	"optional": ["token_id", "username", "request_id", "evidence", "ttl_seconds", "source"],
	"behavior": [
		"mark token-tracking status as revoked",
		"set revoked_at_iso",
		"write token_hash to token-revocation",
		"preserve audit fields",
	],
}

TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
REVOCATION_TABLE = os.environ.get("TOKEN_REVOCATION_TABLE", "token-revocation")

dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table(TRACKING_TABLE)
revocations = dynamodb.Table(REVOCATION_TABLE)


def _utc_iso_now() -> str:
	return datetime.now(timezone.utc).isoformat()


def _extract_payload(event: Any) -> Dict[str, Any]:
	if not isinstance(event, dict):
		return {}

	if isinstance(event.get("detail"), dict):
		return dict(event["detail"])

	if isinstance(event.get("input"), str):
		try:
			parsed = json.loads(event["input"])
			if isinstance(parsed, dict):
				return parsed
		except json.JSONDecodeError:
			pass

	return dict(event)


def _normalize_request(event: Any) -> Dict[str, Any]:
	payload = _extract_payload(event)
	return {
		"source": payload.get("source", "bedrock"),
		"token_hash": payload.get("token_hash"),
		"token_id": payload.get("token_id"),
		"username": payload.get("username"),
		"request_id": payload.get("request_id"),
		"reason": payload.get("reason"),
		"evidence": payload.get("evidence"),
		"ttl_seconds": payload.get("ttl_seconds", 900),
	}


def _lookup_tracking_items(token_hash: str, token_id: str | None) -> list[Dict[str, Any]]:
	if token_id:
		response = tracking.get_item(Key={"token_id": token_id})
		item = response.get("Item")
		return [item] if item else []

	response = tracking.query(
		IndexName="token-hash-index",
		KeyConditionExpression=Key("token_hash").eq(token_hash),
	)
	return response.get("Items", [])


def _revoke_tracking_item(item: Dict[str, Any], req: Dict[str, Any], revoked_at_iso: str) -> None:
	tracking.update_item(
		Key={"token_id": item["token_id"]},
		UpdateExpression="SET #s = :s, revoked_at_iso = :t, revoke_reason = :r",
		ExpressionAttributeNames={"#s": "status"},
		ExpressionAttributeValues={
			":s": "revoked",
			":t": revoked_at_iso,
			":r": req["reason"],
		},
	)


def _write_revocation(item: Optional[Dict[str, Any]], req: Dict[str, Any], revoked_at_iso: str) -> None:
	if not req["token_hash"]:
		return

	tracking_item = item or {}
	expires_at = tracking_item.get("expires_at")
	if expires_at is None:
		expires_at = int(datetime.now(timezone.utc).timestamp()) + int(req["ttl_seconds"])

	revocations.put_item(
		Item={
			"token_hash": req["token_hash"],
			"expires_at": expires_at,
			"revoked_at_iso": revoked_at_iso,
			"reason": req["reason"],
			"token_id": tracking_item.get("token_id"),
			"username": tracking_item.get("username") or req.get("username"),
		},
	)


def lambda_handler(event, context):
	req = _normalize_request(event)
	missing = [key for key in ("token_hash", "reason") if not req.get(key)]

	if missing:
		return {
			"statusCode": 400,
			"headers": {"Content-Type": "application/json"},
			"body": json.dumps(
				{
					"message": "Missing required fields",
					"missing": missing,
					"contract": CONTRACT,
				},
			),
		}

	tracking_items = _lookup_tracking_items(req["token_hash"], req.get("token_id"))
	response = {
		"action": "revoke",
		"status": "accepted",
		"source": req["source"],
		"token_hash": req["token_hash"],
		"reason": req["reason"],
		"revoked_at_iso": _utc_iso_now(),
		"request_id": req.get("request_id"),
		"username": req.get("username"),
		"token_id": req.get("token_id"),
		"ttl_seconds": req.get("ttl_seconds"),
		"evidence": req.get("evidence"),
		"tracking_matches": len(tracking_items),
	}

	if tracking_items:
		for item in tracking_items:
			_revoke_tracking_item(item, req, response["revoked_at_iso"])
			_write_revocation(item, req, response["revoked_at_iso"])
	else:
		_write_revocation(None, req, response["revoked_at_iso"])

	return {
		"statusCode": 200,
		"headers": {"Content-Type": "application/json"},
		"body": json.dumps(response),
	}
