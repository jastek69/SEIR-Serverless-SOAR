# One-Page Architecture: Cognito + API Gateway + DynamoDB Token Control

## Goal

Provide identity-aware API access with Cognito, enforce authorization at API Gateway, and use DynamoDB for token/session telemetry plus immediate revocation checks.

## End-to-end request flow

1. Client signs in with Cognito and receives JWTs.
2. Client calls API with Authorization: Bearer <JWT>.
3. AWS WAF inspects and filters malicious traffic.
4. API Gateway Cognito authorizer validates token signature/claims.
5. Lambda executes only for authorized requests.
6. Lambda writes token/session metadata to token-tracking.
7. Revocation checks read token-revocation first, then token-tracking state.
8. CloudWatch captures operational logs/metrics; S3 can retain long-term audit records.

## Architecture diagram

```mermaid
flowchart LR
    C[Client App] -->|Sign in| CG[Cognito User Pool]
    CG -->|ID/Access JWT| C
    C -->|Authorization: Bearer JWT| WAF[AWS WAF]
    WAF --> APIGW[API Gateway REST]
    APIGW -->|COGNITO_USER_POOLS authorizer| AUTH{JWT valid?}
    AUTH -->|No| DENY[401/403]
    AUTH -->|Yes| L1[python_lambda or node_lambda]

    L1 -->|Issue/track| DDB1[(DynamoDB token-tracking)]
    L1 -->|Revoke check| DDB2[(DynamoDB token-revocation)]

    SCH[EventBridge Scheduler\nrate(5 minutes)] --> DET[detection Lambda]
    DET -->|Mark stale unused| DDB1
    DET -->|Optional revoke entry| DDB2

    APIGW --> CW[CloudWatch Logs and Metrics]
    L1 --> CW
    DET --> CW
    CW --> S3[S3 audit archive optional]
```

ASCII fallback:

```text
Client App
    |
    | sign-in
    v
Cognito User Pool ----> (ID/Access JWT) ----> Client App
    |
    | Authorization: Bearer <JWT>
    v
AWS WAF ---> API Gateway (Cognito Authorizer) ---> [JWT valid?]
                                                                                            | yes         | no
                                                                                            v             v
                                                                     python_lambda/node_lambda   401/403
                                                                                            |
                                                +---------------------+---------------------+
                                                |                                           |
                                                v                                           v
                 DynamoDB token-tracking                        DynamoDB token-revocation

EventBridge Scheduler (rate 5 minutes)
                                    |
                                    v
                     detection Lambda -----> updates tracking/revocation state

API Gateway + Lambdas + detection ---> CloudWatch Logs/Metrics ---> optional S3 audit archive
```

## Trust boundaries

- Public boundary: Client to API Gateway.
- Identity boundary: Cognito user pool and API Gateway authorizer.
- Data boundary: DynamoDB tables for state, revocation, and audit context.
- Observability boundary: CloudWatch logs/metrics and optional immutable S3 archive.

## Token model

- Do not store raw access/refresh tokens.
- Store token_hash (SHA-256) and metadata only.
- Use expires_at as Unix epoch seconds for DynamoDB TTL.
- Use status lifecycle values such as active, used, revoked, expired.

## Data model

### Table: token-tracking

- Primary key: token_id (S)
- Common attributes:
    - token_hash (S)
    - username (S)
    - status (S)
    - used (BOOL)
    - expires_at (N, TTL)
    - issued_at_iso (S)
    - revoked_at_iso (S, optional)
    - reason (S, optional)
- Suggested GSIs:
    - token-hash-index for hash lookup
    - user-expiry-index for user/session analytics
    - status-expiry-index for cleanup and reporting

### Table: token-revocation

- Primary key: token_hash (S)
- Common attributes:
    - expires_at (N, TTL)
    - revoked_at_iso (S)
    - reason (S)

## Runtime behaviors

- Issue token event: write token-tracking row with active state.
- Use token event: update token-tracking status/used flags.
- Revoke token event: write token-revocation row and mark tracking row revoked.
- Validate request token:
    1. Hash incoming token.
    2. Check token-revocation by token_hash.
    3. Check token-tracking status and expires_at.
    4. Allow or deny.
- Scheduled cleanup: EventBridge Scheduler invokes detection Lambda every 5 minutes.

## Security controls

- API Gateway Cognito authorizer enforces JWT auth.
- Lambda performs optional defense-in-depth checks on claims.
- DynamoDB uses SSE and PITR where possible.
- TTL removes stale records automatically.
- Least privilege IAM for Lambda, API Gateway integration, and scheduler roles.

## Operational controls

- CloudWatch log groups per Lambda and API access logs.
- Alarms: Lambda Errors/Throttles, API 4XX/5XX spikes, WAF blocked requests.
- Structured logs: request_id, username/sub, token_id, status transitions, reason.

## Implementation map

- get_token.py: issue tracking write
- update_token.py: used/revoked transitions
- unused_token_detector.py: scheduled scan/delete of stale unused sessions after 5 minutes
- python_lambda.py / node_lambda.js: Cognito claim checks and business logic

---

# DynamoDB + Lambda Token Workflow

This document contains copy-ready snippets for token tracking and revocation using two DynamoDB tables:

- token-tracking
- token-revocation

It also includes Lambda code, environment variable wiring, and Terraform outputs.

## src/easier_get_token.py

```python
import os
import json
import uuid
import hashlib
import time
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
table = dynamodb.Table(TRACKING_TABLE)


def _utc_iso_now():
    return datetime.now(timezone.utc).isoformat()


def _epoch_now():
    return int(time.time())


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def lambda_handler(event, context):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )

    username = claims.get("cognito:username") or claims.get("username") or "unknown-user"

    # In production, token is normally issued by Cognito.
    # This is metadata tracking for lab/session workflows.
    token_id = str(uuid.uuid4())
    raw_token = str(uuid.uuid4())
    token_hash = _sha256_hex(raw_token)

    lifetime_seconds = 900
    expires_at = _epoch_now() + lifetime_seconds

    item = {
        "token_id": token_id,
        "token_hash": token_hash,
        "username": username,
        "status": "active",
        "used": False,
        "expires_at": expires_at,
        "issued_at_iso": _utc_iso_now(),
    }

    table.put_item(Item=item)

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "token_id": token_id,
                "status": "active",
                "expires_at": expires_at,
                "username": username,
            }
        ),
    }
```

### Refactor Example: Lambda-safe + CLI Cognito Flow
Lambda Handler implementation

Flow:

1. API Gateway receives the request with the Cognito JWT.
2. The Cognito authorizer validates the token.
3. API Gateway puts the validated claims into the Lambda event.
4. The Python handler reads those claims and extracts the username.
5. The handler passes that username into the tracking function.

The handler obtains username from the Cognito-authenticated event that API Gateway passes in after successful authorization.
This version is a single file that can be imported safely by Lambda, while still allowing local interactive Cognito login from the command line.

```python
import os
import json
import uuid
import hashlib
import time
from datetime import datetime, timezone

import boto3
import getpass
from botocore.exceptions import ClientError


CLIENT_ID = os.environ.get("COGNITO_APP_CLIENT_ID", "")
REGION = os.environ.get("AWS_REGION", "us-east-1")
TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")


def _utc_iso_now():
    return datetime.now(timezone.utc).isoformat()


def _epoch_now():
    return int(time.time())


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _tracking_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(TRACKING_TABLE)


def track_token_issue(username: str, lifetime_seconds: int = 900):
    token_id = str(uuid.uuid4())
    raw_token = str(uuid.uuid4())
    token_hash = _sha256_hex(raw_token)

    issued_at = _epoch_now()
    expires_at = issued_at + lifetime_seconds

    item = {
        "token_id": token_id,
        "token_hash": token_hash,
        "username": username,
        "status": "active",
        "used": False,
        "expires_at": expires_at,
        "issued_at_iso": _utc_iso_now(),
    }

    _tracking_table().put_item(Item=item)

    return {
        "token_id": token_id,
        "raw_token": raw_token,
        "status": "active",
        "expires_at": expires_at,
        "username": username,
    }


def cognito_user_password_auth(username: str, password: str):
    if not CLIENT_ID:
        raise RuntimeError("Missing COGNITO_APP_CLIENT_ID environment variable")

    client = boto3.client("cognito-idp", region_name=REGION)

    response = client.initiate_auth(
        ClientId=CLIENT_ID,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={"USERNAME": username, "PASSWORD": password},
    )

    challenge_name = response.get("ChallengeName")
    if challenge_name in ("SMS_MFA", "SOFTWARE_TOKEN_MFA"):
        code = input("Enter MFA Code: ")
        code_key = "SMS_MFA_CODE" if challenge_name == "SMS_MFA" else "SOFTWARE_TOKEN_MFA_CODE"
        response = client.respond_to_auth_challenge(
            ClientId=CLIENT_ID,
            ChallengeName=challenge_name,
            Session=response["Session"],
            ChallengeResponses={"USERNAME": username, code_key: code},
        )
    elif challenge_name:
        raise RuntimeError(f"Unsupported Cognito challenge: {challenge_name}")

    return response["AuthenticationResult"]


def lambda_handler(event, context):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
    )
    username = claims.get("cognito:username") or claims.get("username") or "unknown-user"

    tracked = track_token_issue(username=username)

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "token_id": tracked["token_id"],
                "status": tracked["status"],
                "expires_at": tracked["expires_at"],
                "username": tracked["username"],
            }
        ),
    }


def main():
    username = input("Username: ")
    password = getpass.getpass("Password: ")

    try:
        auth = cognito_user_password_auth(username, password)
        print("\n========== TOKENS ==========\n")
        print("ID Token:\n")
        print(auth["IdToken"])
        print("\nAccess Token:\n")
        print(auth["AccessToken"])
        print("\n============================\n")
    except ClientError as e:
        print("\nAuthentication Failed\n")
        message = e.response["Error"].get("Message", str(e))
        if "SECRET_HASH" in message:
            print("This app client requires a client secret.")
            print("Use a Cognito app client configured with no client secret.")
        else:
            print(str(e))
    except Exception as e:
        print("\nAuthentication Failed\n")
        print(str(e))


if __name__ == "__main__":
    main()
```


# Update Token on DynamoDB table


## src/update_token.py

```python
import os
import json
import hashlib
import time
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
REVOCATION_TABLE = os.environ.get("TOKEN_REVOCATION_TABLE", "token-revocation")

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
            UpdateExpression="SET #s = :s, used = :u, revoked_at_iso = :r",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":s": new_status,
                ":u": (action != "revoke"),
                ":r": now_iso,
            },
        )

    if action == "revoke" and token_hash:
        expires_at = now_epoch + 900
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
```

## src/unused_token_detector.py

```python
import json
from datetime import datetime, timezone, timedelta

import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table("token-tracking")


def _parse_iso(s: str):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    threshold = now - timedelta(minutes=5)

    updated = 0
    scanned = 0
    last_key = None

    while True:
        scan_args = {
            "FilterExpression": Attr("used").eq(False) & Attr("status").eq("active")
        }
        if last_key:
            scan_args["ExclusiveStartKey"] = last_key

        resp = tracking.scan(**scan_args)
        items = resp.get("Items", [])
        scanned += len(items)

        for item in items:
            issued_raw = item.get("issued_at_iso")
            token_id = item.get("token_id")
            if not issued_raw or not token_id:
                continue

            issued = _parse_iso(issued_raw)
            if issued <= threshold:
                tracking.update_item(
                    Key={"token_id": token_id},
                    UpdateExpression="SET #s = :s, revoke_reason = :r, revoked_at_iso = :t",
                    ExpressionAttributeNames={"#s": "status"},
                    ExpressionAttributeValues={
                        ":s": "revoked",
                        ":r": "unused_after_5_minutes",
                        ":t": now.isoformat(),
                    },
                )
                updated += 1

        last_key = resp.get("LastEvaluatedKey")
        if not last_key:
            break

    return {
        "statusCode": 200,
        "body": json.dumps({"scanned": scanned, "updated": updated}),
    }
```

## lambda.tf environment block

Add this environment block to get_token, update_token, and unused_token_detector functions:

```hcl
environment {
  variables = {
    TOKEN_TRACKING_TABLE   = aws_dynamodb_table.dynamoDb_token_tracking.name
    TOKEN_REVOCATION_TABLE = aws_dynamodb_table.dynamoDb_token_revocation.name
  }
}
```

## outputs.tf additions

```hcl
output "token_tracking_table_name" {
  value       = aws_dynamodb_table.dynamoDb_token_tracking.name
  description = "DynamoDB token tracking table name"
}

output "token_tracking_table_arn" {
  value       = aws_dynamodb_table.dynamoDb_token_tracking.arn
  description = "DynamoDB token tracking table ARN"
}

output "token_revocation_table_name" {
  value       = aws_dynamodb_table.dynamoDb_token_revocation.name
  description = "DynamoDB token revocation table name"
}

output "token_revocation_table_arn" {
  value       = aws_dynamodb_table.dynamoDb_token_revocation.arn
  description = "DynamoDB token revocation table ARN"
}
```

## Read outputs

```bash
terraform output token_tracking_table_name
terraform output token_revocation_table_name
terraform output -json
```

## Cognito integration

Use API Gateway Cognito authorizers as the primary gate and keep a lightweight in-function claim check for defense in depth and clearer audit logs.

### Python handler claim checks (src/python_lambda.py)

```python
import json
from datetime import datetime, timezone


def _claims_from_event(event):
        return (
                event.get("requestContext", {})
                .get("authorizer", {})
                .get("claims", {})
        )


def lambda_handler(event, context):
        claims = _claims_from_event(event)
        user_sub = claims.get("sub")
        username = claims.get("cognito:username") or claims.get("username")

        if not user_sub or not username:
                return {
                        "statusCode": 401,
                        "headers": {"Content-Type": "application/json"},
                        "body": json.dumps({"message": "Unauthorized: missing Cognito claims"}),
                }

        response = {
                "message": f"Hello {username} from Python!",
                "sub": user_sub,
                "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(response),
        }
```

### Node handler claim checks (src/node_lambda.js)

```javascript
exports.handler = async (event) => {
    const claims = event?.requestContext?.authorizer?.claims || {};
    const sub = claims.sub;
    const username = claims["cognito:username"] || claims.username;

    if (!sub || !username) {
        return {
            statusCode: 401,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: "Unauthorized: missing Cognito claims" }),
        };
    }

    return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            message: `HELLO ${username.toUpperCase()} FROM NODE!`,
            sub,
        }),
    };
};
```

### API Gateway authorizer requirements

Make sure your API methods are configured with:

- authorization = COGNITO_USER_POOLS
- authorizer_id = your Cognito authorizer resource id
- identity source = method.request.header.Authorization

If this is configured correctly, invalid or missing JWTs are rejected by API Gateway before Lambda executes.

### Optional scope enforcement

If you add Cognito resource server scopes, enforce them on API methods with `authorization_scopes` and send access tokens containing those scopes.


## Cognito

## Cognito State and tfvar settings
Cognito State is handled separately when enabled in tfvars: 
`cognito_state_enabled = true`

Cognito backend settings are configured in the tfvars:
cognito_state_bucket = "<name of cognito bucket>"
cognito_state_key = "where/to/place/cognito-terraform-state.tfstate"
cognito_state_enabled = true or false
cognito_state_region = "us-west-2" # must match the bucket's actual region when enabled

## The Cognito remote state is handled in the `api.tf`

