

RBAC
Role-Based Access Control (RBAC) is a security model where:

End to End Request Flow
1. Client signs in with Cognito and receives JWTs.
2. Client calls API with Authorization: Bearer <JWT>.
3. AWS WAF inspects and filters malicious traffic.
4. API Gateway Cognito authorizer validates token signature/claims.
5. Lambda executes only for authorized requests.
6. Lambda writes token/session metadata to token-tracking.
7. Revocation checks read token-revocation first, then token-tracking state.
8. CloudWatch captures operational logs/metrics; S3 can retain long-term audit records.


Access is assigned to roles, not directly to users.

Cognito for OAuth/JWT identity.
DynamoDB for session metadata, token revocation records, OAuth state/nonce, device tracking, and audit events.

Cognito:
OAuth/JWT identity
issue ID/access/refresh tokens
REST API validates access tokens locally using Cognito’s JWKS/public keys.


RBAC:
Layered Cognito Scope + Lambda RBAC



AWS WAF:
- Filters malicious HTTP traffic before API Gateway
- Blocks payloads such as XSS/SQLi when rules match

Cognito User Pool:
- Authenticates the user and issues JWTs
- Issues ID/access/refresh tokens after login and MFA

API Gateway Cognito Authorizer
- Validates the JWT and required OAuth scope
- Requires a valid access token with `rbac-api/admin`


Lambda:
- Enforces final RBAC
- Reads Cognito claims/groups and allows or denies the request

DynamoDB:
- Tracks token/session metadata 
- Stores token hash, status, timestamps, revocation/audit metadata


# API Gateway
API Gateway Cognito Authorizer
- Validates the JWT and required OAuth scope
- Requires a valid access token with `rbac-api/admin`

Token validation happens through Cognito/API Gateway.
JWT validation and OAuth scope enforcement happen through Cognito and API Gateway.


API Gateway acts as a coarse authorization gate. It verifies that the caller supplied a valid Cognito access token containing the required `rbac-api/admin` scope. After that, Lambda receives the request and performs the final RBAC decision from Cognito group claims.

REST API
Makes you define:
Resource → path (/python)
Method → HTTP verb (GET)
Integration → backend (Lambda)
Deployment → publish changes

1. The Cognito resource server defines API-level scopes: e.g. admin and user
2. The RBAC app client can request both scopes
3. The user app client is limited to the user scope
4. Both app clients point to the same RBAC user pool. Users are separated by Cognito group membership

This keeps the responsibilities separate:
- API Gateway checks API-level permission with access-token scopes.
- Lambda checks application-level RBAC with Cognito group claims.

#### Tokens: ID Tokens vs Access Tokens
Token validation happens through Cognito/API Gateway.

- ID token: authorize API calls based on identity claims
    - Proves who the signed-in user is
    - Claim/group based RBAC in Lambda 

- Access token: authorize API calls based on custom scopes for protected resources.
    - Proves what the caller is allowed to access
    - API Gateway scope authorization

Scopes
Resource Server
Create a COGNITO_USER_POOLS authorizer.
Point it at the Cognito user pool.
Attach the authorizer to the protected API method.
Client must call API Gateway with Cognito JWT

Arrows:
make sure JWT validation is visually attached to the Cognito authorizer/API Gateway path

| User Type | Scope |
| --------- | ----- |
| Admin users | `rbac-api/admin` and possibly `rbac-api/user` |
| Normal users | `rbac-api/user` only |



# Lambda
decides access based on identity claims
Lambda enforces RBAC from Cognito group claims
admin -> 200
non-admin -> 403

The Lambda executes for valid JWTs, then denies non-admin users with 403:
```
Lambda executes for valid tokens and enforces group-based authorization
```


# Cloudwatch
infrastructure logs,
operational logs,
and alarms

# Eventbridge
Triggers the detector Lambda

EventBridge invokes unused_token_detector every 5 minutes

unused_token_detector scans DynamoDB for issued-but-unused tokens

# SOAR
SOAR Workflow:
unused_token_detector -> Bedrock SOAR prompt -> S3 Reports Bucket

Then:
S3 report event -> Translator Lambda -> translated report -> S3 Output/Audit Bucket



# SSM Parameter
SSM used as the runtime prompt store for SOAR, so the Lambda can fetch prompt text dynamically instead of hardcoding it.

1. Terraform creates an SSM parameter
2. The parameter value is loaded from your local prompt file
3. The Lambda is told which parameter to read
4. At runtime, the detector reads that env var in unused_token_detector.py, then calls SSM GetParameter in unused_token_detector.py
5. If SSM returns a value, that prompt is used and marked as source ssm in unused_token_detector.
6. If SSM is missing/unavailable, it falls back to built-in text and marks source fallback in unused_token_detector.


KMS Notes:
This project does not currently require a customer-managed KMS key for DynamoDB because the table stores token-tracking and revocation metadata, not plaintext tokens, passwords, API keys, or application secrets.
DynamoDB encryption at rest is enabled by default using AWS-owned encryption keys. 
Service access is controlled through IAM least-privilege policies, while end-user API access is controlled separately through Cognito/API Gateway RBAC and Lambda authorization logic.

DynamoDB currently uses default encryption at rest.
A customer-managed KMS key is not required because the table stores token metadata and revocation state, not plaintext secrets or full tokens.
If the design later stores sensitive user data, plaintext tokens, refresh tokens, or requires compliance evidence for customer-managed encryption keys, DynamoDB should be updated to use a customer-managed KMS key with explicit key policies.



Would only use KMS if you need:
Customer-managed key rotation/audit controls.
Explicit key ownership for compliance.
Cross-account key control.
Fine-grained deny/allow controls around key usage.
Stronger evidence for regulated workloads.


Cases where customer-managed KMS for DynamoDB is commonly necessary:
Compliance asks for customer-managed keys
Examples: “all sensitive data stores must use CMKs,” key rotation evidence, key ownership, CloudTrail auditing of key use.

You store sensitive regulated data
Examples: PII, PHI, financial data, credentials, secrets, full tokens, refresh tokens, API keys, session material.

You need separation of duties
Example: app admins can manage DynamoDB, but only security/platform owners can manage or disable encryption keys.

You need emergency data lockout
Disabling the KMS key can make encrypted data inaccessible without deleting the table.

Cross-account access is involved
Example: one account owns the table and another account/service needs controlled decrypt access.

You need explicit deny controls
Example: deny decrypt unless the request comes through DynamoDB, from a specific account, role, or condition.



# S3 - Immutability + Encryption

S3: immutable audit archive: compliance-grade long-term records.
long-term audit evidence with Object lock for immutability
immutable audit archive: compliance-grade long-term records.

S3 stores SOAR reports and evidence artifacts. Encryption at rest should be enabled by default. Customer-managed KMS is optional unless compliance, audit, or sensitive-data requirements require explicit key ownership and KMS usage controls.
For immutable evidence retention, S3 versioning and Object Lock are the primary controls; KMS protects confidentiality but does not make logs immutable.

```
S3 encryption = protects data at rest
S3 bucket policy/IAM = controls who can read/write/delete objects
S3 Object Lock/versioning = controls immutability and retention
KMS customer-managed key = gives stronger control/audit over encryption key usage
```

If S3 stores SOAR reports, Markdown summaries, JSON evidence, and test artifacts without secrets/full tokens, default S3 encryption is usually acceptable.
If S3 stores audit evidence, incident records, regulated data, or anything you want to preserve as official security evidence, then S3 Object Lock/versioning is more relevant than KMS for immutability.
If compliance requires customer-managed key ownership/audit, then use SSE-KMS with a customer-managed KMS key.



# DynamoDB
DynamoDB supports the surrounding security workflow:

- Token/session tracking
- Token hash storage instead of raw token storage
- Status values such as `active`, `used`, or `revoked`
- TTL-based cleanup
- Revocation denylist lookups for sensitive operations
- Audit evidence for unused-token detection and SOAR reporting

Tables:
TokenTracking table
TokenRevocation table

Token Tracking Summary
DynamoDB supports token/session state, revocation metadata, unused-token detection, and SOAR audit evidence. It does not validate JWT signatures. 

### Tables
- `token-tracking`: stores issued token/session metadata.
- `token-revocation`: stores revoked token hashes for denylist checks.

NOTE: Raw tokens are never stored. The system stores only a SHA-256 `token_hash` plus metadata such as username, status, issue time, expiry, and audit timestamps.

### Token Lifecycle
1. When a token is issued, write one item to `token-tracking`.
2. Store `token_hash`, `username`, `status`, `issued_at`, and `expires_at`.
3. Use `expires_at` as Unix epoch seconds so DynamoDB TTL can clean up old records.
4. When a token is used, update the tracking item status or `used` flag.
5. When a token is revoked, update `token-tracking` and add a matching item to `token-revocation`.
6. EventBridge invokes `unused_token_detector.py` on schedule to find issued-but-unused tokens and generate SOAR evidence.



# Security - Monitoring – logs, metrics, alerting

- Cloudwatch - infrastructure logs, operational logs and alarms
- S3: immutable audit archive: compliance-grade long-term records.
  - long-term audit evidence with Object lock for immutability
  - immutable audit archive: compliance-grade long-term records.

DynamoDB provides:
- Token/session tracking
- Revocation denylist support
- TTL-based cleanup
- Audit evidence
- Unused-token detection support
- SOAR reporting context - the evidence source


### Validation Boundary
Cognito/API Gateway handles:
- JWT signature validation
- Token issuer/audience validation
- Token expiration checks
- OAuth scope enforcement, such as `rbac-api/admin`

Lambda handles:
- Final group-based RBAC from Cognito claims
- Revocation/session-state checks against DynamoDB
- Token usage updates for audit tracking

DynamoDB handles:
- Stored token/session state
- Revocation records
- Audit metadata
- TTL cleanup

### Immediate Revocation Options
Use one or more of:
- Short access-token lifetimes
- Refresh-token revocation
- DynamoDB-backed denylist checks for sensitive operations

### Related Lambda Functions
- `easier_get_token.py`: creates token-tracking records.
- `update_token.py`: marks tokens used or revoked and can write revocation records.
- `unused_token_detector.py`: scans for issued-but-unused tokens and supports SOAR reporting.
 

## SOAR and DynanoDB: the evidence source - it tracks token/session state.
I only use DynamoDB for secure token lifecycle handling.
Table 1: token-tracking
- Purpose: token/session lifecycle metadata
- Primary key: token_id (S)
- GSIs:
	- user-expiry-index (username + expires_at)
	- status-expiry-index (status + expires_at)
	- token-hash-index (token_hash)

Table 2: token-revocation
	- Purpose: fast denylist lookup for revoked tokens
	- Primary key: token_hash (S)
	- TTL: expires_at (epoch seconds)

What DynamoDB does is provide the evidence context for unused-token SOAR reporting. It does not store the SOAR report itself. The detector reads token/session records from `token-tracking`, converts stale unused records into findings, sends those findings to Bedrock for analysis, and writes the final report artifacts to S3.

DynamoDB stores the token/session facts that the SOAR report is based on.
- unused_token_detector.py converts stale unused token records into findings.
- Bedrock turns those findings into SOAR reports.
- S3 stores the final report.

SOAR Flow:
token-tracking records
  -> unused_token_detector.py scans active unused records
  -> stale records become findings
  -> Bedrock generates analysis from the findings
  -> S3 stores Markdown and JSON evidence artifacts

DynamoDB provides context in this way:
Cognito token issued
  -> token metadata written to token-tracking
  -> EventBridge runs unused_token_detector.py
  -> detector scans token-tracking
  -> unused/stale token findings become SOAR report input
  -> Bedrock generates the report
  -> report is written to S3/Reports


For the SOAR report, the detector turns those records into incident context:
- User authenticated successfully
- JWT token issued
- Token was not used within threshold window
- Token remains active or unused
- Finding age calculated from issue time
- Recommended analyst actions generated

DynamoDB tracks token/session state.
- unused_token_detector.py converts stale unused token records into findings.
- Bedrock turns those findings into SOAR reports.
- S3 stores the final report.

# DynamoDB Global Tables:
[textDynamoDB - GSI](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/gsi-throttling.html)
[Using GSI](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)

- Global data access with local reads and writes
    Global tables enable you to read data from and write data to any Region. DynamoDB replicates your data asynchronously to other Regions, typically within 1 second. Data replication doesn’t impact the performance of your application writes. With a global table, each replica table stores the same set of data items, and your data is eventually consistent in all Regions. While your application can perform strongly consistent reads in the same Region, the reads of data replicated from other regions of your global table are always eventually consistent, due to asynchronous nature of data replication. Transactional operations provide ACID guarantees only in the Region where the write occurs originally.

- Resiliency – Global tables provide a 99.999% uptime SLA and allow you to build disaster-proof solutions with multi-Region resiliency.
    Your application can implement custom logic to detect when a global table’s Region becomes isolated or degraded in order to redirect reads and writes to a different Region. In addition, DynamoDB tracks any writes that have been performed but haven’t yet been propagated to other Regions. If, for some reason, the communication gets interrupted, DynamoDB propagates any pending writes when the Region comes back online.

- Conflict resolution – Write conflicts can occur when writes to the same item in a global table are made simultaneously in two different Regions. To ensure data consistency, DynamoDB global tables use a last-writer-wins conflict resolution mechanism, so all the replica tables agree on the latest update and converge toward a state in which they all have identical data.

- Operational efficiency – Global tables eliminate the difficult work of replicating data so you can focus on your application’s business logic. You can monitor DynamoDB using Amazon CloudWatch (see DynamoDB Metrics and dimensions) and track global tables replication delays using the ReplicationLatency metric. ReplicationLatency is expressed in milliseconds and is emitted for every source-Region/destination-Region pair.
From a cost perspective, you pay the usual DynamoDB prices for read capacity and storage, along with data transfer charges for cross-Region replication. Write capacity is billed in terms of replicated write capacity units. Refer to Amazon DynamoDB pricing for more details.




SSM parameter Store - I don't do any of that. I only use it as the runtime prompt store for SOAR so Lambda can dynamically fetch the prompt instead of it being hardcoded. 
1 - The prompt loads the value from a stored text file.
2 - An ENV var tells Lambda which parameter to read.
3 - The detector reds the env var and calls SSM.

This is done in the unused_token_detector.py.
If it is used then it is marked as source SSM in unused_token_detector.py.
If SSM is missing or something happened then it uses the built-in text and marks the source as fallback in the lambda function.

