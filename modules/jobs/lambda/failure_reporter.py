"""Bedrock failure reporter — post-mortems for dead-lettered and stalled jobs.

Two trigger shapes, one handler:
  1. SQS event source mapping on each job DLQ (message exhausted its receives
     — the worker crashed or never recorded an outcome).
  2. EventBridge JobStalled events from the stuck-job detector (heartbeat
     went silent past the threshold).

For each failed job: pull the DynamoDB record + recent CloudWatch log lines
mentioning the job_id, ask Bedrock for a Markdown post-mortem, write it to
s3://<bucket>/reports/jobs/<job_id>.md, and stamp report_key on the record.

The report bucket is the workstation root's bucket, discovered at runtime via
the /stability-matrix/bucket SSM handshake parameter unless REPORTS_BUCKET is
set. Prompt template lives in SSM (versioned, edited there — not in code).
Warm containers cache both; recycle the container to pick up edits (same
trade-off as the SOAR reporting pipeline).
"""

import json
import os
import time

import boto3

ddb = boto3.client("dynamodb")
s3 = boto3.client("s3")
ssm = boto3.client("ssm")
logs = boto3.client("logs")
bedrock = boto3.client("bedrock-runtime")

JOBS_TABLE = os.environ["JOBS_TABLE"]
MODEL_ID = os.environ["BEDROCK_MODEL_ID"]
PROMPT_PARAM_NAME = os.environ.get("PROMPT_PARAM_NAME", "/bedrock/jobs-failure-prompt")
REPORTS_BUCKET = os.environ.get("REPORTS_BUCKET", "")
REPORTS_BUCKET_PARAM = os.environ.get("REPORTS_BUCKET_PARAM", "/stability-matrix/bucket")
LOG_GROUPS = [g for g in os.environ.get("LOG_GROUPS", "").split(",") if g]
MAX_OUTPUT_TOKENS = int(os.environ.get("MAX_OUTPUT_TOKENS", "1500"))
TEMPERATURE = float(os.environ.get("TEMPERATURE", "0.3"))
LOG_LOOKBACK_HOURS = int(os.environ.get("LOG_LOOKBACK_HOURS", "24"))

_cache = {}


def log(level, message, **fields):
    print(json.dumps({"level": level, "message": message, **fields}), flush=True)


def _bucket():
    if REPORTS_BUCKET:
        return REPORTS_BUCKET
    if "bucket" not in _cache:
        _cache["bucket"] = ssm.get_parameter(Name=REPORTS_BUCKET_PARAM)[
            "Parameter"
        ]["Value"]
    return _cache["bucket"]


def _prompt_template():
    if "prompt" not in _cache:
        _cache["prompt"] = ssm.get_parameter(
            Name=PROMPT_PARAM_NAME, WithDecryption=True
        )["Parameter"]["Value"]
    return _cache["prompt"]


def _flatten(item):
    """DynamoDB typed item -> plain dict (S/N only — matches the jobs schema)."""
    out = {}
    for k, v in (item or {}).items():
        if "S" in v:
            out[k] = v["S"]
        elif "N" in v:
            out[k] = int(v["N"])
    return out


def _job_record(job_id):
    return _flatten(
        ddb.get_item(TableName=JOBS_TABLE, Key={"job_id": {"S": job_id}}).get("Item")
    )


def _recent_logs(job_id):
    """Best-effort: lines mentioning the job_id from the control-plane Lambdas.
    Worker logs live in journald on the EC2 instance, not CloudWatch — the
    prompt tells the model so it doesn't over-conclude from their absence."""
    excerpts = []
    start = int((time.time() - LOG_LOOKBACK_HOURS * 3600) * 1000)
    for group in LOG_GROUPS:
        try:
            events = logs.filter_log_events(
                logGroupName=group,
                filterPattern=f'"{job_id}"',
                startTime=start,
                limit=50,
            ).get("events", [])
            excerpts.extend(
                {"log_group": group, "message": e["message"].strip()[:500]}
                for e in events
            )
        except Exception as exc:
            log("warn", "log group fetch failed", log_group=group, error=str(exc))
    return excerpts[:100]


def _generate_report(context_block):
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": MAX_OUTPUT_TOKENS,
        "temperature": TEMPERATURE,
        "messages": [
            {
                "role": "user",
                "content": _prompt_template()
                + "\n\nJob context:\n```json\n"
                + json.dumps(context_block, indent=2, default=str)
                + "\n```",
            }
        ],
    }
    response = bedrock.invoke_model(modelId=MODEL_ID, body=json.dumps(body))
    return json.loads(response["body"].read())["content"][0]["text"]


def _report_job(job_id, trigger, extra):
    record = _job_record(job_id)
    context_block = {
        "trigger": trigger,
        "job_record": record or "NO RECORD FOUND IN JOBS TABLE",
        "control_plane_log_excerpts": _recent_logs(job_id),
        "note": (
            "Worker runtime logs are in journald on the GPU instance "
            "(journalctl -u comfyui-worker), not CloudWatch."
        ),
    }
    context_block.update(extra)

    report = _generate_report(context_block)
    key = f"reports/jobs/{job_id}.md"
    s3.put_object(
        Bucket=_bucket(),
        Key=key,
        Body=report.encode(),
        ContentType="text/markdown",
    )
    ddb.update_item(
        TableName=JOBS_TABLE,
        Key={"job_id": {"S": job_id}},
        UpdateExpression="SET report_key = :k",
        ExpressionAttributeValues={":k": {"S": key}},
    )
    log("info", "post-mortem written", job_id=job_id, trigger=trigger, key=key)


def lambda_handler(event, context):
    reported = 0

    if "Records" in event:  # DLQ arrival via SQS event source mapping
        for record in event["Records"]:
            try:
                message = json.loads(record["body"])
                job_id = message["job_id"]
            except (json.JSONDecodeError, KeyError):
                log("error", "unparseable DLQ message", body=record.get("body", "")[:500])
                continue
            _report_job(
                job_id,
                "dead-lettered (worker never recorded an outcome after max receives)",
                {"original_message": message},
            )
            reported += 1
    elif event.get("detail-type") == "JobStalled":
        detail = event.get("detail", {})
        job_id = detail.get("job_id")
        if job_id:
            _report_job(job_id, "stalled (worker heartbeat went silent)", {})
            reported += 1
    else:
        log("warn", "unrecognized event shape", keys=sorted(event.keys()))

    return {"reported": reported}
