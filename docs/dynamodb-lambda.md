# One-Page Architecture: Cognito + API Gateway + DynamoDB Token Control

## Goal

Provide identity-aware API access with Cognito, enforce coarse authorization at API Gateway with access-token scopes, and use DynamoDB for token/session telemetry plus revocation-state support.

## End-to-end request flow

1. Client signs in with Cognito and receives JWTs.
2. Client calls API with `Authorization: Bearer <ACCESS_TOKEN>`.
3. AWS WAF inspects and filters malicious traffic.
4. API Gateway Cognito authorizer validates the token and required OAuth scope.
5. Lambda executes only after WAF and API Gateway allow the request.
6. Lambda performs final group-based RBAC from Cognito claims.
7. Lambda writes token/session metadata to token-tracking.
8. Optional revocation/session-state checks read token-revocation first, then token-tracking state.
9. CloudWatch captures operational logs/metrics; S3 can retain long-term audit records.

## Architecture diagram

#### Mermaid format:

```mermaid
flowchart LR
    C[Client App] -->|Sign in| CG[Cognito User Pool]
    CG -->|ID/Access JWT| C
    C -->|Authorization: Bearer ACCESS_TOKEN| WAF[AWS WAF]
    WAF --> APIGW[API Gateway REST]
    APIGW -->|COGNITO_USER_POOLS authorizer + scope| AUTH{JWT and scope valid?}
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

#### ASCII format:

```text
Client App
    |
    | sign-in
    v
Cognito User Pool ----> (ID/Access JWT) ----> Client App
    |
    | Authorization: Bearer <ACCESS_TOKEN>
    v
AWS WAF ---> API Gateway (Cognito Authorizer + scope check) ---> [JWT and scope valid?]
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
- Optional revocation/session-state check:
    1. Hash incoming token.
    2. Check token-revocation by token_hash.
    3. Check token-tracking status and expires_at.
    4. Allow or deny.
- Scheduled cleanup: EventBridge Scheduler invokes detection Lambda every 5 minutes.

## SOAR reporting context

DynamoDB provides the evidence context for unused-token SOAR reporting. It does not store the SOAR report itself. The detector reads token/session records from `token-tracking`, converts stale unused records into findings, sends those findings to Bedrock for analysis, and writes the final report artifacts to S3.

| DynamoDB Field / Detector Value | SOAR Reporting Use |
| ------------------------------- | ------------------ |
| `token_id` | Identifies the tracked token/session event without exposing the raw JWT |
| `username` | Shows which user/account the tracked token was issued for |
| `issued_at_iso` | Provides the human-readable issue time used to calculate token age |
| `age_minutes` | Calculated by `unused_token_detector.py` from `issued_at_iso`; shows how long the token has remained unused |
| `status` | Indicates whether the tracking record is active; the detector accepts lowercase `status` and legacy uppercase `Status` |
| `used` | Indicates whether the token/session was used; stale findings require `used = false` |
| `token_kind` | Identifies the type/source of tracked record, such as `cognito-id-token`, `synthetic-tracking-token`, or `legacy-or-unknown` |
| `records_examined` | Count of DynamoDB records scanned during the detector run |
| `matched` | Count of records matching the active/unused scan filter |
| `alerted` | Count of findings published as unused-token alerts |
| `trigger_source` | Shows whether the scan was scheduled, manual, or otherwise triggered |
| `reason` | Explains why the SOAR run was invoked, such as manual review or unused-token threshold scan |

SOAR flow:

```text
token-tracking records
  -> unused_token_detector.py scans active unused records
  -> stale records become findings
  -> Bedrock generates analysis from the findings
  -> S3 stores Markdown and JSON evidence artifacts
```

## Security controls

- API Gateway Cognito authorizer enforces JWT auth and configured OAuth scopes.
- Lambda performs final group-based RBAC and optional defense-in-depth checks on claims.
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

## sample code: `easier_get_token.py` implementing DynamoDB Tracking Table

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

# token issuance - 900 sec (15 mins)
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
        "Status": "active",
        "used": False,
        "expires_at": expires_at,
        "issued_at_iso": _utc_iso_now()
    }
    
    _tracking_table().put_item(Item=item)
    
    
    print(f"Generated token for user {username}: {raw_token}")
    
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "token": token_id,
                "status": "active",
                "expires_at": expires_at,
                "username": username
            }
        ),
    }

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
#### Lambda Handler implementation

Flow:

1. API Gateway receives the request with the Cognito access token.
2. The Cognito authorizer validates the token and required API scope.
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
[Gognito Handler Claims](https://aws.amazon.com/blogs/security/use-amazon-cognito-to-add-claims-to-an-identity-token-for-fine-grained-authorization/): This defines the process of retrieving, decoding, and validating the JSON Web Tokens (JWTs). Fine grained Authorization.

***The Risk: [Verifying JSON web tokens](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html)***
JSON web tokens (JWTs) can be decoded, read, and modified easily. A modified access token creates a risk of privilege escalation. A modified ID token creates a risk of impersonation. Your application trusts your user pool as a token issuer, but what if a user intercepts the token in transit? You must ensure that your application is receiving the same token that Amazon Cognito issued.

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

### Current API Gateway scope enforcement

This project uses Cognito resource server scopes on API Gateway methods with `authorization_scopes`. Clients must send access tokens containing the required scope, such as `rbac-api/admin`.

[OAuth API Resource Server](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-define-resource-servers.html)
After you configure a domain for your user pool, Amazon Cognito automatically provisions an OAuth 2.0 authorization server and a hosted web UI with sign-up and sign-in pages that your app can present to your users.

A resource server is an OAuth 2.0 API server. To secure access-protected resources, it validates that access tokens from your user pool contain the scopes that authorize the requested method and path in the API that it protects. It verifies the issuer based on the token signature, validity based on token expiration time, and access level based on the scopes in token claims. User pool scopes are in the access token scope claim.

API Authorization:
- Access token
- ID token
- Verified Permissions: creates and assigns a Lambda authorizer that processes ID or access tokens from your request Authorization header. This Lambda authorizer passes your token to your policy store, where Verified Permissions compares it to policies and returns an allow or deny decision to the authorizer.


### DynamoDB Global Tables

Note
`Partition Key` (`PK`) of an item is also known as its `hash attribute` . The term “hash attribute” derives from DynamoDB’s usage of an internal hash function to evenly distribute data items across partitions, based on their partition key values.

`Primary Key` Restrictions: You cannot use a boolean data type for any attribute defined in your primary key (Partition Key or Sort Key). Key schemas are strictly constrained to scalar types: String (S), Number (N), or Binary (B)

`Sort Key` (`SK`) of an item is also known as its range attribute . The term “range attribute” derives from the way DynamoDB stores items with the same partition key physically close together, in sorted order by the sort key value.



key attributes and non-key attributes
- `key_schema` is only for table primary key and GSI keys.
- Key attributes (table PK and index keys) support only scalar key types (S, N, B) and must be stable query keys. If `used` is in any `key schema`, it cannot be a boolean BOOL. BOOL values are not good state keys
- `key_type` is used inside `key_schema {}` block for indexes

NOTES:
- Keys/indexes are for lookup patterns
- Key attributes support only scalar key types (S, N, B) and must be stable query keys
- GSI: key_schema is only for table primary key and GSI keys.
- Keys/indexes model access patterns, not mutable flags

- `used`: Should not be part of the key schema - treat as a regular item field for business state and filtering - it is metadata for (BOOL). It is is persisted on the token record and can be read from there. 

Lambda writes and reads must stay consistent with DynamoDB schema constraints
- Use indexes on:
    - `status`,
    - username,
    - expires_at,
    - token_hash

These are the query dimensions defined inside `unused_token_detector.py`:

Query combinations:
- token_hash index: fast lookup for revoke/check
- status + expires_at index: find active tokens by expiry window
- username + expires_at index: user-focused token timelines
- expires_at: query time windows/sort by expiry

Global Tables are a DynamoDB multi-Region replication feature. They allow reads and writes in Multiple Regions and replicate data asynchronously between replica tables.

Use Global Tables when the application needs multi-Region resiliency or lower-latency local reads/writes. They are not required for Single Regions.

Important characteristics:

- Replication is asynchronous, so replicated reads are eventually consistent.
- Strongly consistent reads are only available in the Region where the read occurs against that Region's replica.
- Simultaneous writes to the same item in different Regions use last-writer-wins conflict resolution.
- Cross-Region replication adds cost for replicated writes, storage, and data transfer.


### DynamoDB Schema and Read Consistency in This Project

This project uses DynamoDB in a way that combines key-based lookups and non-key metadata filtering.

- Key/index attributes must be consistent with table/index definitions:
    - `token_id`, `token_hash`, `status`, `username`, and `expires_at` are key/index attributes and must keep stable names and compatible scalar types where indexed.
    - Lambda writes to these fields must match the table and GSI key definitions.
- Non-key attributes are flexible:
    - `used` is intentionally a non-key metadata field (`BOOL`) and is safe to write/read as a normal item attribute.
    - Do not put mutable state flags like `used` into `key_schema`.

Read consistency notes for this configuration:

- Base table reads (`GetItem`/`Query` on table primary key) can be strongly consistent in a single Region when requested.
- GSI reads are eventually consistent only.
- Because detector and reporting flows use GSIs (for example `status-expiry-index` and `token-hash-index`), a recent write may take a short time to appear in index query results.
- This is expected behavior and should be considered in workflows that read immediately after writes.


### Important Considerations for GSI:
Where GSIs help:

1. Access-pattern queries:
    1. by user + time window
    2. by token hash
    3. by status + expiry

2. Operational reporting:
    1. “show active tokens for user X”
    2. “find tokens expiring soon”

3. Scale:
    1. high read throughput on alternate keys without changing PK

***Limits you must account for:***

1. GSI reads are eventually consistent only.
2. Index propagation is asynchronous (small lag after writes).
3. Not a ledger:
    1. no immutability guarantees
    2. no cryptographic chaining
    3. no native non-repudiation semantics

***For financial-grade tracking, combine:***
1. DynamoDB base table as source of truth for current state.
2. GSIs for query/access views.
3. Append-only audit stream:
    1. DynamoDB Streams -> immutable store (S3 Object Lock / QLDB / blockchain layer).
4. Idempotency keys + conditional writes for correctness.
5. Signed event records and strict time-ordering controls.

***For blockchain-style tracking:***

1. GSIs are good for indexing wallet/user/token activity views.
2. They are not a substitute for on-chain verification or append-only consensus records.

***Practical design rule:***
1. Use GSIs for “find and analyze”.
2. Use immutable event logs/ledger for “prove and audit”.



References:
- [DynamoDB Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
- [DynamoDB Describe Table](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/describe-table.html)
- [DynamoDB GSIs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
- [DynamoDB Schemaless](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SQLtoNoSQL.CreateTable.html)
- [DynamoDB Table Constraints](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Constraints.html)


### Querying DynamoDB
[DynamoDB Table Read Consistency](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html)

Query the GSI by key then apply `used` as the filter:
```python
from boto3.dynamodb.conditions import Key, Attr

resp = tracking.query(
    IndexName="status-expiry-index",
    KeyConditionExpression=Key("status").eq("active") & Key("expires_at").gte(cutoff_epoch),
    FilterExpression=Attr("used").eq(False),
)
items = resp.get("Items", [])
```



## Cognito

### Cognito Pool Wiring

This stack creates the Cognito RBAC user pool locally in `cognito.tf`.
API Gateway authorizers in `api.tf` trust `aws_cognito_user_pool.cognito_rbac_pool.arn` directly.

# WAF Bedrcok Analyzer
see WAF.md


## A Lambda, a WAF, a DynamoDB walk into a bar
1. Waf Logs are sent to CloudWatch
2. Lambda reads last few minutes of CloudWatch WAF logs
3. Lambda extracts the following:
```
 source IP
 country
 URI
 HTTP method
 WAF action
 terminating rule
 ```
 4. Lambda send thosee details to Bedrock
 5. Bedrock returns a SOC-style summary
  .5a Summary sent to S3 for translation
 6. Lambda prints the summary to CloudWatch
  6a. Lambda sends the summary to S3 for translation
7. Lambda sends WAF events to DynamoDB for tracking


Lambda enhancement:

Lambda Execution Role
```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:FilterLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "bedrock:InvokeModel"
          ],
          "Resource": "*"
        },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:PutItem"
         ],
         "Resource": "arn:aws:dynamodb:<region>:<account-id>:table/waf-events"
        }
      ]
    }
```



Add DynamoDB client:
```
dynamodb = boto3.resource("dynamodb")          
table = dynamodb.Table("waf-events")
```

Store Event - inside processing loop:
```
import uuid

  table.put_item(
     Item={
       "event_id": str(uuid.uuid4()),
       "timestamp": str(waf_summary["timestamp"]),
        "source_ip": waf_summary["client_ip"],
        "country": waf_summary["country"],
        "uri": waf_summary["uri"],
        "method": waf_summary["method"],
        "action": waf_summary["action"],
        "rule": waf_summary["terminating_rule_id"]
         }
)

```

DynamoDB Table Design - a new Table
- Table: waf-events
- Partition Key: event_id Type: String

DynamoDB Waf Event Table output:
```JSON
    {
      "event_id": "123456",
      "timestamp": "2026-06-23T18:00:00Z",
      "source_ip": "1.2.3.4",
      "country": "RU",
      "uri": "/python",
      "method": "GET",
      "action": "BLOCK",
      "rule": "AWSManagedRulesCommonRuleSet"
    }
```



## Glossary
