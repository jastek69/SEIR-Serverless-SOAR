"""EventBridge-scheduled detector: flag running jobs whose heartbeat went silent.

Workers MUST heartbeat updated_at every 60-120s while running (frozen contract).
Any job still `running` with updated_at older than STALLED_THRESHOLD_SECONDS is
marked `stalled` and a JobStalled event is emitted for downstream automation
(the Bedrock failure reporter subscribes to these).
"""

import json
import os
import time

import boto3

dynamodb = boto3.client("dynamodb")
events = boto3.client("events")

JOBS_TABLE = os.environ["JOBS_TABLE"]
STATUS_INDEX = os.environ.get("STATUS_INDEX", "status-index")
STALLED_THRESHOLD_SECONDS = int(os.environ.get("STALLED_THRESHOLD_SECONDS", "600"))
EVENT_SOURCE = os.environ.get("EVENT_SOURCE", "jobs.detector")


def _log(level, message, **fields):
    print(json.dumps({"level": level, "message": message, **fields}))


def lambda_handler(event, context):
    cutoff = int(time.time()) - STALLED_THRESHOLD_SECONDS
    stalled = []
    kwargs = {
        "TableName": JOBS_TABLE,
        "IndexName": STATUS_INDEX,
        "KeyConditionExpression": "#s = :running AND updated_at < :cutoff",
        "ExpressionAttributeNames": {"#s": "status"},
        "ExpressionAttributeValues": {
            ":running": {"S": "running"},
            ":cutoff": {"N": str(cutoff)},
        },
    }

    while True:
        page = dynamodb.query(**kwargs)
        for item in page.get("Items", []):
            job_id = item["job_id"]["S"]
            try:
                # Condition re-checks status so a worker that resumed (or
                # finished) between query and update is left alone.
                dynamodb.update_item(
                    TableName=JOBS_TABLE,
                    Key={"job_id": {"S": job_id}},
                    UpdateExpression="SET #s = :stalled, updated_at = :now",
                    ConditionExpression="#s = :running AND updated_at < :cutoff",
                    ExpressionAttributeNames={"#s": "status"},
                    ExpressionAttributeValues={
                        ":stalled": {"S": "stalled"},
                        ":running": {"S": "running"},
                        ":cutoff": {"N": str(cutoff)},
                        ":now": {"N": str(int(time.time()))},
                    },
                )
            except dynamodb.exceptions.ConditionalCheckFailedException:
                continue
            stalled.append({"job_id": job_id, "type": item["type"]["S"]})
            _log("warn", "job stalled", job_id=job_id, job_type=item["type"]["S"],
                 last_heartbeat=int(item["updated_at"]["N"]))

        if "LastEvaluatedKey" not in page:
            break
        kwargs["ExclusiveStartKey"] = page["LastEvaluatedKey"]

    if stalled:
        # 10 entries max per PutEvents call
        for i in range(0, len(stalled), 10):
            events.put_events(
                Entries=[
                    {
                        "Source": EVENT_SOURCE,
                        "DetailType": "JobStalled",
                        "Detail": json.dumps(job),
                    }
                    for job in stalled[i : i + 10]
                ]
            )

    _log("info", "detector sweep complete", stalled_count=len(stalled),
         threshold_seconds=STALLED_THRESHOLD_SECONDS)
    return {"stalled": len(stalled)}
