#!/usr/bin/env python3
"""
Local stdio MCP server for the Phase 12 SOAR agents.

Control plane only: the EventBridge-driven pipeline (correlation agent ->
SOAR response agent) keeps running autonomously; this server exposes
analyst-facing reads and explicit agent invocations as MCP tools.

Reads go straight to DynamoDB/S3 (read-only). Actions delegate to the
deployed agent Lambdas via lambda:InvokeFunction — business logic stays in
the agents, never here.

Run it with Claude Code (stdio, local AWS credentials):

    claude mcp add soar-agents -- python mcp-server/mcp_server.py

Promotion path (see docs/MCP.md): same tools behind FastMCP's
streamable_http_app() on Lambda, with the API Gateway JWT authorizer from
mcp.tf.txt providing Cognito RBAC.
"""

import os

# This project's shell often exports a broken AWS_CA_BUNDLE (WSL UNC path)
# that fails every AWS SDK call. Drop it if it doesn't resolve to a file.
_ca_bundle = os.environ.get("AWS_CA_BUNDLE")
if _ca_bundle and not os.path.exists(_ca_bundle):
    os.environ.pop("AWS_CA_BUNDLE", None)

import json
from decimal import Decimal
from functools import lru_cache
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from mcp.server.fastmcp import FastMCP

# ============================================================
# Configuration (defaults match the Terraform resource names)
# ============================================================

AWS_REGION = os.environ.get("AWS_REGION", "us-west-2")

FINDINGS_TABLE = os.environ.get(
    "CORRELATION_FINDINGS_TABLE", "waf-correlation-findings"
)
INCIDENTS_TABLE = os.environ.get(
    "SECURITY_INCIDENTS_TABLE", "security-incidents"
)

CORRELATION_AGENT_FUNCTION = os.environ.get(
    "CORRELATION_AGENT_FUNCTION", "waf-threat-correlation-agent"
)
SOAR_RESPONSE_FUNCTION = os.environ.get(
    "SOAR_RESPONSE_FUNCTION", "soar-response-agent"
)
EXECUTIVE_DASHBOARD_FUNCTION = os.environ.get(
    "EXECUTIVE_DASHBOARD_FUNCTION", "executive-dashboard-agent"
)

REPORT_PREFIX = os.environ.get("REPORT_PREFIX", "executive-reports")

_session = boto3.session.Session(region_name=AWS_REGION)
dynamodb = _session.resource("dynamodb")
lambda_client = _session.client("lambda")
s3_client = _session.client("s3")
sts_client = _session.client("sts")

mcp = FastMCP("soar-agents")


# ============================================================
# Helpers
# ============================================================

def to_native(value: Any) -> Any:
    """Convert DynamoDB Decimal values into JSON-safe numbers."""
    if isinstance(value, list):
        return [to_native(item) for item in value]
    if isinstance(value, dict):
        return {key: to_native(item) for key, item in value.items()}
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    return value


@lru_cache(maxsize=1)
def report_bucket() -> str:
    """Resolve the executive reports bucket (env override or convention)."""
    override = os.environ.get("REPORT_BUCKET")
    if override:
        return override
    account_id = sts_client.get_caller_identity()["Account"]
    return f"taaops-lambda-waf-executive-reports-{account_id}"


def scan_all(table_name: str, max_items: int = 500) -> list[dict[str, Any]]:
    """Scan a small lab table, paginating up to max_items."""
    table = dynamodb.Table(table_name)
    items: list[dict[str, Any]] = []
    kwargs: dict[str, Any] = {}
    while True:
        response = table.scan(**kwargs)
        items.extend(response.get("Items", []))
        last_key = response.get("LastEvaluatedKey")
        if not last_key or len(items) >= max_items:
            return to_native(items[:max_items])
        kwargs["ExclusiveStartKey"] = last_key


def matches(item: dict[str, Any], severity: str | None, status: str | None) -> bool:
    if severity and str(item.get("severity", "")).upper() != severity.upper():
        return False
    if status and str(item.get("status", "")).upper() != status.upper():
        return False
    return True


def invoke_agent(function_name: str, payload: dict[str, Any]) -> dict[str, Any]:
    """Synchronously invoke an agent Lambda and unwrap its response."""
    try:
        response = lambda_client.invoke(
            FunctionName=function_name,
            InvocationType="RequestResponse",
            Payload=json.dumps(payload).encode(),
        )
    except (ClientError, BotoCoreError) as error:
        return {"error": f"{type(error).__name__}: {error}"}

    raw = response["Payload"].read()
    if response.get("FunctionError"):
        return {"error": f"Lambda FunctionError: {raw.decode(errors='replace')}"}

    try:
        result = json.loads(raw)
    except json.JSONDecodeError:
        return {"error": f"Non-JSON Lambda response: {raw.decode(errors='replace')}"}

    # Agents return API-style {"statusCode", "body"} envelopes; unwrap them.
    if isinstance(result, dict) and "body" in result and "statusCode" in result:
        try:
            body = json.loads(result["body"])
        except (json.JSONDecodeError, TypeError):
            body = result["body"]
        return {"statusCode": result["statusCode"], "result": body}

    return {"result": result}


# ============================================================
# Read tools — DynamoDB / S3, read-only
# ============================================================

@mcp.tool()
def list_findings(
    severity: str | None = None,
    status: str | None = None,
    limit: int = 20,
) -> list[dict[str, Any]]:
    """List WAF correlation findings, newest first (compact projection).

    severity: LOW | MEDIUM | HIGH | CRITICAL. status: e.g. OPEN,
    RESPONSE_COMPLETED. Use get_finding for the full record.
    """
    items = [
        item
        for item in scan_all(FINDINGS_TABLE)
        if matches(item, severity, status)
    ]
    items.sort(key=lambda i: str(i.get("created_at", "")), reverse=True)
    return [
        {
            "finding_id": item.get("finding_id"),
            "created_at": item.get("created_at"),
            "severity": item.get("severity"),
            "risk_score": item.get("risk_score"),
            "status": item.get("status"),
            "primary_source_ip": item.get("primary_source_ip"),
            "primary_target": item.get("primary_target"),
            "event_count": item.get("event_count"),
            "incident_id": item.get("incident_id"),
        }
        for item in items[: max(1, limit)]
    ]


@mcp.tool()
def get_finding(finding_id: str, include_evidence: bool = False) -> dict[str, Any]:
    """Retrieve one correlation finding by ID.

    The evidence package is large; it is omitted unless include_evidence
    is true. The Bedrock correlation report is always included.
    """
    table = dynamodb.Table(FINDINGS_TABLE)
    response = table.get_item(Key={"finding_id": finding_id})
    item = response.get("Item")
    if not item:
        return {"error": f"Finding {finding_id} does not exist."}
    item = to_native(item)
    if not include_evidence:
        item.pop("evidence", None)
        item["evidence_omitted"] = True
    return item


@mcp.tool()
def list_incidents(
    severity: str | None = None,
    status: str | None = None,
    limit: int = 20,
) -> list[dict[str, Any]]:
    """List security incidents, newest first (compact projection).

    Use get_incident for the full record including the analyst summary.
    """
    items = [
        item
        for item in scan_all(INCIDENTS_TABLE)
        if matches(item, severity, status)
    ]
    items.sort(key=lambda i: str(i.get("created_at", "")), reverse=True)
    return [
        {
            "incident_id": item.get("incident_id"),
            "finding_id": item.get("finding_id"),
            "created_at": item.get("created_at"),
            "severity": item.get("severity"),
            "priority": item.get("priority"),
            "status": item.get("status"),
            "playbook": item.get("playbook"),
            "risk_score": item.get("risk_score"),
            "human_review_required": item.get("human_review_required"),
        }
        for item in items[: max(1, limit)]
    ]


@mcp.tool()
def get_incident(incident_id: str) -> dict[str, Any]:
    """Retrieve one security incident by ID (e.g. INC-<finding_id>),
    including the full analyst summary."""
    table = dynamodb.Table(INCIDENTS_TABLE)
    response = table.get_item(Key={"incident_id": incident_id})
    item = response.get("Item")
    if not item:
        return {"error": f"Incident {incident_id} does not exist."}
    return to_native(item)


@mcp.tool()
def get_executive_report(report_format: str = "pdf") -> dict[str, Any]:
    """Get a presigned URL (1h) for the most recent executive report.

    report_format: pdf or json. Reports are produced by
    generate_executive_report under executive-reports/YYYY/MM/DD/.
    """
    report_format = report_format.lower()
    if report_format not in ("pdf", "json"):
        return {"error": "report_format must be 'pdf' or 'json'."}

    bucket = report_bucket()
    newest = None
    paginator = s3_client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=f"{REPORT_PREFIX}/"):
        for obj in page.get("Contents", []):
            if f"/{report_format}/" not in obj["Key"]:
                continue
            if newest is None or obj["LastModified"] > newest["LastModified"]:
                newest = obj

    if newest is None:
        return {
            "error": (
                f"No {report_format} reports found in s3://{bucket}/"
                f"{REPORT_PREFIX}/. Run generate_executive_report first."
            )
        }

    url = s3_client.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": newest["Key"]},
        ExpiresIn=3600,
    )
    return {
        "bucket": bucket,
        "key": newest["Key"],
        "last_modified": newest["LastModified"].isoformat(),
        "size_bytes": newest["Size"],
        "presigned_url": url,
        "expires_in_seconds": 3600,
    }


# ============================================================
# Action tools — delegate to the deployed agent Lambdas
# ============================================================

@mcp.tool()
def run_correlation(window_minutes: int = 60) -> dict[str, Any]:
    """Run the WAF threat correlation agent now over the given lookback
    window. Creates a finding (and emits the EventBridge event that
    triggers the SOAR response agent) if enough WAF events exist."""
    return invoke_agent(
        CORRELATION_AGENT_FUNCTION,
        {"correlation_window_minutes": window_minutes},
    )


@mcp.tool()
def rerun_soar_response(finding_id: str) -> dict[str, Any]:
    """Re-drive the SOAR response agent for a specific finding.

    Idempotent: findings already in a completed status are skipped, and
    incident creation is a conditional put on INC-<finding_id>."""
    return invoke_agent(SOAR_RESPONSE_FUNCTION, {"finding_id": finding_id})


@mcp.tool()
def generate_executive_report(report_period_hours: int = 24) -> dict[str, Any]:
    """Generate a new executive security report (PDF + JSON in S3)
    covering the given period. Takes up to ~2 minutes; fetch the result
    with get_executive_report."""
    return invoke_agent(
        EXECUTIVE_DASHBOARD_FUNCTION,
        {"report_period_hours": report_period_hours},
    )


if __name__ == "__main__":
    mcp.run()  # stdio transport
