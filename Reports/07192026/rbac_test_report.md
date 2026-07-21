# RBAC and WAF Test Report

- Generated (UTC): 2026-07-20T01:55:51Z
- Region: us-west-2
- Python API: https://d2zxhf2ieg.execute-api.us-west-2.amazonaws.com/prod
- Node API: https://uapov0k2d4.execute-api.us-west-2.amazonaws.com/prod

Writing full run transcript to: /c/Users/John Sweeney/aws/lambda/SEIR-Serverless-SOAR/Reports/rbac_test_report.md
Invoking Python Lambda function directly for testing...
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
Lambda function invoked. Response saved to response.json.
Invoking Node Lambda function directly for testing...
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
Node Lambda function invoked. Response saved to node_response.json.
Invoking Python Lambda function with invalid tokens for negative testing...
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
Python Lambda function invoked with invalid tokens. Response saved to invalid_response.json.
Invoking unused token detector manually with SOAR forced...
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
Unused token detector invoked. Response saved to unused-detector-response.json.
Testing script execution completed. Check the generated reports in /c/Users/John Sweeney/aws/lambda/SEIR-Serverless-SOAR/Reports and the Lambda responses in response.json, node_response.json, and invalid_response.json for results.
testing Negative auth scenario with Node Lambda function...
HTTP/1.1 401 Unauthorized
Date: Mon, 20 Jul 2026 01:56:16 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: 8db3b4dd-ecd5-436d-9eeb-a544e39d3e12
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: AyD6KEwwPHcEKxg=

{"message":"Unauthorized"}
HTTP/1.1 401 Unauthorized
Date: Mon, 20 Jul 2026 01:56:17 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: 1462e2c4-eb2f-4a83-ae4c-573751ed9fbe
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: AyD6VFqGvHcEGBg=

{"message":"Unauthorized"}
PASS: Python no-token auth (expected=401 actual=401)
PASS: Node no-token auth (expected=401 actual=401)
Positive auth test (valid token)
HTTP/1.1 200 OK
Date: Mon, 20 Jul 2026 01:56:20 GMT
Content-Type: application/json
Content-Length: 98
Connection: keep-alive
x-amzn-RequestId: badc1f00-764a-4a04-8cc7-241caa19c7b8
x-amz-apigw-id: AyD6uGZKvHcEILw=
X-Amzn-Trace-Id: Root=1-6a5d8044-33a72d733b94edd4584e2caf;Parent=739067c85c0cbed9;Sampled=0;Lineage=1:315d35d1:0

{"message": "Hello theo from Python!", "timestamp": "2026-07-20T01:56:20.253113", "role": "admin"}
HTTP/1.1 200 OK
Date: Mon, 20 Jul 2026 01:56:22 GMT
Content-Type: application/json
Content-Length: 67
Connection: keep-alive
x-amzn-RequestId: abe23b51-3a85-4167-851d-9ab66fc506b3
x-amz-apigw-id: AyD6_FHMvHcECIA=
X-Amzn-Trace-Id: Root=1-6a5d8045-67ddbe7a7a9c4f0e64d3e2dd;Parent=1b5539802f00b577;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
PASS: Python admin auth (expected=200 actual=200)
PASS: Node admin auth (expected=200 actual=200)
Scope/RBAC deny test with non-admin access token (expected: 403)
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:23 GMT
Content-Type: application/json
Content-Length: 50
Connection: keep-alive
x-amzn-RequestId: 9c807ecb-9643-4973-8e14-af75c44ddd82
x-amz-apigw-id: AyD7KHd7vHcEOQA=
X-Amzn-Trace-Id: Root=1-6a5d8046-0997a7dd49e5e9c425fc3df6;Parent=09bf2c1d2b709928;Sampled=0;Lineage=1:315d35d1:0

{"message": "Access denied: admin group required"}
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:23 GMT
Content-Type: application/json
Content-Length: 49
Connection: keep-alive
x-amzn-RequestId: d0dad5d7-78da-411d-9e90-314b2614055c
x-amz-apigw-id: AyD7PEHSPHcEACg=
X-Amzn-Trace-Id: Root=1-6a5d8047-0aa7c8b8021990b67b17371d;Parent=5131be3fa014a1ee;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"Access denied: admin group required"}
PASS: Python non-admin scope/RBAC deny (expected=403 actual=403)
PASS: Node non-admin scope/RBAC deny (expected=403 actual=403)
WAF strict XSS block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:24 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 47568f50-74a6-4861-be4c-afed4e586f5a
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: AyD7XHOaPHcEuUw=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:24 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 2ecf95e3-d051-4b1f-8000-a7ba4a3d4ce8
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: AyD7cFvTvHcEhoQ=

{"message":"Forbidden"}
PASS: Python WAF strict XSS (expected=403 actual=403)
PASS: Node WAF strict XSS (expected=403 actual=403)
WAF strict SQLi block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:25 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 5699b8b9-b87b-4dd4-954b-61c277d34637
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: AyD7hEUNvHcEh0Q=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Mon, 20 Jul 2026 01:56:25 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 61b545e4-5ff1-4c83-b126-047fab533ff8
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: AyD7mHXQvHcEMtA=

{"message":"Forbidden"}
PASS: Python WAF SQLi (expected=403 actual=403)
## WAF Strict Block Result
PASS: Node WAF SQLi (expected=403 actual=403)
Strict WAF summary: XSS Python=403 Node=403; SQLi Python=403 Node=403; Result=PASS

- Python XSS status: 403
- Node XSS status: 403
- Python SQLi status: 403
- Node SQLi status: 403
- Result: PASS

Querying main DynamoDB table for entries related to example_user_id...
{
    "Table": {
        "AttributeDefinitions": [
            {
                "AttributeName": "expires_at",
                "AttributeType": "N"
            },
            {
                "AttributeName": "status",
                "AttributeType": "S"
            },
            {
                "AttributeName": "token_hash",
                "AttributeType": "S"
            },
            {
                "AttributeName": "token_id",
                "AttributeType": "S"
            },
            {
                "AttributeName": "username",
                "AttributeType": "S"
            }
        ],
        "TableName": "token-tracking",
        "KeySchema": [
            {
                "AttributeName": "token_id",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "ACTIVE",
        "CreationDateTime": "2026-07-19T15:52:49.020000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking",
        "TableId": "68af8bc5-c357-49db-9949-2179e9a0e346",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-19T15:52:49.020000-07:00"
        },
        "GlobalSecondaryIndexes": [
            {
                "IndexName": "status-expiry-index",
                "KeySchema": [
                    {
                        "AttributeName": "status",
                        "KeyType": "HASH"
                    },
                    {
                        "AttributeName": "expires_at",
                        "KeyType": "RANGE"
                    }
                ],
                "Projection": {
                    "ProjectionType": "ALL"
                },
                "IndexStatus": "ACTIVE",
                "ProvisionedThroughput": {
                    "NumberOfDecreasesToday": 0,
                    "ReadCapacityUnits": 0,
                    "WriteCapacityUnits": 0
                },
                "IndexSizeBytes": 0,
                "ItemCount": 0,
                "IndexArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking/index/status-expiry-index",
                "WarmThroughput": {
                    "ReadUnitsPerSecond": 12000,
                    "WriteUnitsPerSecond": 4000,
                    "Status": "ACTIVE"
                }
            },
            {
                "IndexName": "token-hash-index",
                "KeySchema": [
                    {
                        "AttributeName": "token_hash",
                        "KeyType": "HASH"
                    }
                ],
                "Projection": {
                    "ProjectionType": "ALL"
                },
                "IndexStatus": "ACTIVE",
                "ProvisionedThroughput": {
                    "NumberOfDecreasesToday": 0,
                    "ReadCapacityUnits": 0,
                    "WriteCapacityUnits": 0
                },
                "IndexSizeBytes": 0,
                "ItemCount": 0,
                "IndexArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking/index/token-hash-index",
                "WarmThroughput": {
                    "ReadUnitsPerSecond": 12000,
                    "WriteUnitsPerSecond": 4000,
                    "Status": "ACTIVE"
                }
            },
            {
                "IndexName": "user-expiry-index",
                "KeySchema": [
                    {
                        "AttributeName": "username",
                        "KeyType": "HASH"
                    },
                    {
                        "AttributeName": "expires_at",
                        "KeyType": "RANGE"
                    }
                ],
                "Projection": {
                    "ProjectionType": "ALL"
                },
                "IndexStatus": "ACTIVE",
                "ProvisionedThroughput": {
                    "NumberOfDecreasesToday": 0,
                    "ReadCapacityUnits": 0,
                    "WriteCapacityUnits": 0
                },
                "IndexSizeBytes": 0,
                "ItemCount": 0,
                "IndexArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking/index/user-expiry-index",
                "WarmThroughput": {
                    "ReadUnitsPerSecond": 12000,
                    "WriteUnitsPerSecond": 4000,
                    "Status": "ACTIVE"
                }
            }
        ],
        "SSEDescription": {
            "Status": "ENABLED",
            "SSEType": "KMS",
            "KMSMasterKeyArn": "arn:aws:kms:us-west-2:015195098145:key/f0cc4189-0c80-4c67-8912-024a60f29a64"
        },
        "DeletionProtectionEnabled": false,
        "WarmThroughput": {
            "ReadUnitsPerSecond": 12000,
            "WriteUnitsPerSecond": 4000,
            "Status": "ACTIVE"
        }
    }
}
{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0
}
Checking token-revocation DynamoDB table for any revoked tokens...
{
    "Table": {
        "AttributeDefinitions": [
            {
                "AttributeName": "token_hash",
                "AttributeType": "S"
            }
        ],
        "TableName": "token-revocation",
        "KeySchema": [
            {
                "AttributeName": "token_hash",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "ACTIVE",
        "CreationDateTime": "2026-07-19T15:52:56.903000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-revocation",
        "TableId": "e8fb8135-dfc8-499d-b3c5-6de9b5aee871",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-19T15:52:56.903000-07:00"
        },
        "SSEDescription": {
            "Status": "ENABLED",
            "SSEType": "KMS",
            "KMSMasterKeyArn": "arn:aws:kms:us-west-2:015195098145:key/f0cc4189-0c80-4c67-8912-024a60f29a64"
        },
        "DeletionProtectionEnabled": false,
        "WarmThroughput": {
            "ReadUnitsPerSecond": 12000,
            "WriteUnitsPerSecond": 4000,
            "Status": "ACTIVE"
        }
    }
}
{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}
Checking EventBridge Scheduler for the presence of the scheduled rule that processes tokens...
[
    {
        "Arn": "arn:aws:scheduler:us-west-2:015195098145:schedule/default/Invoke-unused-token-schedule",
        "CreationDate": "2026-07-19T15:58:21.981000-07:00",
        "GroupName": "default",
        "LastModificationDate": "2026-07-19T15:58:21.981000-07:00",
        "Name": "Invoke-unused-token-schedule",
        "State": "ENABLED",
        "Target": {
            "Arn": "arn:aws:lambda:us-west-2:015195098145:function:unused_token_detector_function"
        }
    }
]
{
    "ActionAfterCompletion": "NONE",
    "Arn": "arn:aws:scheduler:us-west-2:015195098145:schedule/default/Invoke-unused-token-schedule",
    "CreationDate": "2026-07-19T15:58:21.981000-07:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-07-19T15:58:21.981000-07:00",
    "Name": "Invoke-unused-token-schedule",
    "ScheduleExpression": "rate(5 minutes)",
    "ScheduleExpressionTimezone": "UTC",
    "State": "ENABLED",
    "Target": {
        "Arn": "arn:aws:lambda:us-west-2:015195098145:function:unused_token_detector_function",
        "Input": "{\"force_soar\":false,\"reason\":\"Unused token check invoked by EventBridge Scheduler\",\"source\":\"eventbridge-scheduler\"}",
        "RetryPolicy": {
            "MaximumEventAgeInSeconds": 86400,
            "MaximumRetryAttempts": 185
        },
        "RoleArn": "arn:aws:iam::015195098145:role/unused-token-schedule-role"
    }
}
Checking CloudWatch Logs for recent entries in the Python Lambda log group...
2026-07-20T01:50:15.828000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 INIT_START Runtime Version: python:3.9.v133	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:b46f7bc0f3da8071d1b824471f2c69c8766b756b827eb0455d2118c622ae7bcf
2026-07-20T01:50:16.320000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: 426db50d-3478-40e9-99b4-e515012f47ef Version: $LATEST
2026-07-20T01:50:16.320000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA", "Host": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a5d7ed7-16add0aa02a5cf364b0e9d68", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA"], "Host": ["d2zxhf2ieg.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a5d7ed7-16add0aa02a5cf364b0e9d68"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "c9vgk2", "authorizer": {"claims": {"sub": "68a1a3f0-e011-7005-cdd9-32dc4f4127e5", "cognito:groups": "user", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T", "version": "2", "client_id": "4hqt9ikctmesulmh0hbqbs00ta", "origin_jti": "018a2a74-71cd-4714-a2ea-83a14616cc67", "event_id": "905d011e-f8d7-47c5-ba91-13a1de4948af", "token_use": "access", "scope": "openid rbac-api/user", "auth_time": "1784510932", "exp": "Mon Jul 20 02:28:52 UTC 2026", "iat": "Mon Jul 20 01:28:52 UTC 2026", "jti": "5719825d-cb4c-4e74-89a4-7d42e80cada6", "username": "user.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "AyDBtGT_vHcEQHA=", "requestTime": "20/Jul/2026:01:50:15 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "d2zxhf2ieg", "requestTimeEpoch": 1784512215218, "requestId": "57021f9a-d6e4-441d-80b0-f3bfa7bbbc6c", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "deploymentId": "ooqxqq", "apiId": "d2zxhf2ieg"}, "body": null, "isBase64Encoded": false}
2026-07-20T01:50:16.322000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: 426db50d-3478-40e9-99b4-e515012f47ef
2026-07-20T01:50:16.322000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: 426db50d-3478-40e9-99b4-e515012f47ef	Duration: 1.57 ms	Billed Duration: 490 ms	Memory Size: 128 MB	Max Memory Used: 81 MB	Init Duration: 487.97 ms
2026-07-20T01:52:25.695000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: f4e6ba51-646b-44c2-af31-90af6b3480f7 Version: $LATEST
2026-07-20T01:52:25.700000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw", "Host": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a5d7f59-53538da378d75f0a08d1e8bc", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw"], "Host": ["d2zxhf2ieg.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a5d7f59-53538da378d75f0a08d1e8bc"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "Norrin"}, "multiValueQueryStringParameters": {"name": ["Norrin"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "c9vgk2", "authorizer": {"claims": {"sub": "28414310-f071-701b-336a-55324d59b5bd", "cognito:groups": "admin", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T", "version": "2", "client_id": "4hqt9ikctmesulmh0hbqbs00ta", "origin_jti": "cbd790e9-4fff-4275-816f-86c0dc5b2f20", "event_id": "b4f5ea41-f749-4512-b049-7d7b39f10b50", "token_use": "access", "scope": "rbac-api/admin openid rbac-api/user", "auth_time": "1784510079", "exp": "Mon Jul 20 02:14:39 UTC 2026", "iat": "Mon Jul 20 01:14:39 UTC 2026", "jti": "32c296ce-0752-4475-8cd0-d946eeb5f4a7", "username": "admin.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "AyDWFELlvHcEEog=", "requestTime": "20/Jul/2026:01:52:25 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "d2zxhf2ieg", "requestTimeEpoch": 1784512345639, "requestId": "ea33866b-abdf-4220-9175-3026f704a56f", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "deploymentId": "ooqxqq", "apiId": "d2zxhf2ieg"}, "body": null, "isBase64Encoded": false}
2026-07-20T01:52:26.060000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Response: {"message": "Hello Norrin from Python!", "timestamp": "2026-07-20T01:52:25.700699", "role": "admin"}
2026-07-20T01:52:26.081000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: f4e6ba51-646b-44c2-af31-90af6b3480f7
2026-07-20T01:52:26.081000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: f4e6ba51-646b-44c2-af31-90af6b3480f7	Duration: 386.26 ms	Billed Duration: 387 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-20T01:55:56.134000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: 6b71da33-eb45-48a0-8058-024f677bf9a4 Version: $LATEST
2026-07-20T01:55:56.136000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {}
2026-07-20T01:55:56.136000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: 6b71da33-eb45-48a0-8058-024f677bf9a4
2026-07-20T01:55:56.136000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: 6b71da33-eb45-48a0-8058-024f677bf9a4	Duration: 1.38 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-20T01:56:03.137000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: b7e83f6b-aee6-4d25-a1a5-e7650f30a2c2 Version: $LATEST
2026-07-20T01:56:03.137000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {}
2026-07-20T01:56:03.138000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: b7e83f6b-aee6-4d25-a1a5-e7650f30a2c2
2026-07-20T01:56:03.138000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: b7e83f6b-aee6-4d25-a1a5-e7650f30a2c2	Duration: 1.11 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-20T01:56:20.252000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: c355657a-669f-4371-90e7-5878493eb614 Version: $LATEST
2026-07-20T01:56:20.260000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw", "Host": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a5d8044-33a72d733b94edd4584e2caf", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw"], "Host": ["d2zxhf2ieg.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a5d8044-33a72d733b94edd4584e2caf"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "theo"}, "multiValueQueryStringParameters": {"name": ["theo"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "c9vgk2", "authorizer": {"claims": {"sub": "28414310-f071-701b-336a-55324d59b5bd", "cognito:groups": "admin", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T", "version": "2", "client_id": "4hqt9ikctmesulmh0hbqbs00ta", "origin_jti": "cbd790e9-4fff-4275-816f-86c0dc5b2f20", "event_id": "b4f5ea41-f749-4512-b049-7d7b39f10b50", "token_use": "access", "scope": "rbac-api/admin openid rbac-api/user", "auth_time": "1784510079", "exp": "Mon Jul 20 02:14:39 UTC 2026", "iat": "Mon Jul 20 01:14:39 UTC 2026", "jti": "32c296ce-0752-4475-8cd0-d946eeb5f4a7", "username": "admin.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "AyD6uGZKvHcEILw=", "requestTime": "20/Jul/2026:01:56:20 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "d2zxhf2ieg", "requestTimeEpoch": 1784512580195, "requestId": "badc1f00-764a-4a04-8cc7-241caa19c7b8", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "deploymentId": "ooqxqq", "apiId": "d2zxhf2ieg"}, "body": null, "isBase64Encoded": false}
2026-07-20T01:56:20.521000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Response: {"message": "Hello theo from Python!", "timestamp": "2026-07-20T01:56:20.253113", "role": "admin"}
2026-07-20T01:56:20.541000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: c355657a-669f-4371-90e7-5878493eb614
2026-07-20T01:56:20.541000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: c355657a-669f-4371-90e7-5878493eb614	Duration: 288.66 ms	Billed Duration: 289 ms	Memory Size: 128 MB	Max Memory Used: 82 MB
2026-07-20T01:56:23.020000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 START RequestId: 150a4453-9c11-42e6-bd84-badead848289 Version: $LATEST
2026-07-20T01:56:23.021000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA", "Host": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a5d8046-0997a7dd49e5e9c425fc3df6", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA"], "Host": ["d2zxhf2ieg.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a5d8046-0997a7dd49e5e9c425fc3df6"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "c9vgk2", "authorizer": {"claims": {"sub": "68a1a3f0-e011-7005-cdd9-32dc4f4127e5", "cognito:groups": "user", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T", "version": "2", "client_id": "4hqt9ikctmesulmh0hbqbs00ta", "origin_jti": "018a2a74-71cd-4714-a2ea-83a14616cc67", "event_id": "905d011e-f8d7-47c5-ba91-13a1de4948af", "token_use": "access", "scope": "openid rbac-api/user", "auth_time": "1784510932", "exp": "Mon Jul 20 02:28:52 UTC 2026", "iat": "Mon Jul 20 01:28:52 UTC 2026", "jti": "5719825d-cb4c-4e74-89a4-7d42e80cada6", "username": "user.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "AyD7KHd7vHcEOQA=", "requestTime": "20/Jul/2026:01:56:22 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "d2zxhf2ieg", "requestTimeEpoch": 1784512582975, "requestId": "9c807ecb-9643-4973-8e14-af75c44ddd82", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "d2zxhf2ieg.execute-api.us-west-2.amazonaws.com", "deploymentId": "ooqxqq", "apiId": "d2zxhf2ieg"}, "body": null, "isBase64Encoded": false}
2026-07-20T01:56:23.022000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 END RequestId: 150a4453-9c11-42e6-bd84-badead848289
2026-07-20T01:56:23.022000+00:00 2026/07/20/[$LATEST]41936308e21b4c27a6f859c1d7423415 REPORT RequestId: 150a4453-9c11-42e6-bd84-badead848289	Duration: 1.53 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 82 MB
2026-07-20T01:50:17.040000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 INIT_START Runtime Version: nodejs:24.v48	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:adfa9c68b2b34ae1cba34f70c4369649bca17aea5fe29e10414b040bf256e6c6
2026-07-20T01:50:17.334000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 START RequestId: feab39a6-76a9-490f-9571-8b61ad5a2db2 Version: $LATEST
2026-07-20T01:50:17.347000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:50:17.347Z	feab39a6-76a9-490f-9571-8b61ad5a2db2	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA","Host":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a5d7ed8-1b4d7b3f6b972ffc7fb90387","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA"],"Host":["uapov0k2d4.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a5d7ed8-1b4d7b3f6b972ffc7fb90387"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"lotoky","authorizer":{"claims":{"sub":"68a1a3f0-e011-7005-cdd9-32dc4f4127e5","cognito:groups":"user","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T","version":"2","client_id":"4hqt9ikctmesulmh0hbqbs00ta","origin_jti":"018a2a74-71cd-4714-a2ea-83a14616cc67","event_id":"905d011e-f8d7-47c5-ba91-13a1de4948af","token_use":"access","scope":"openid rbac-api/user","auth_time":"1784510932","exp":"Mon Jul 20 02:28:52 UTC 2026","iat":"Mon Jul 20 01:28:52 UTC 2026","jti":"5719825d-cb4c-4e74-89a4-7d42e80cada6","username":"user.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"AyDB9HbGPHcEPBw=","requestTime":"20/Jul/2026:01:50:16 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"uapov0k2d4","requestTimeEpoch":1784512216828,"requestId":"723011d2-eb3a-4ea2-86b2-19533f6a05da","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","deploymentId":"1hvxxe","apiId":"uapov0k2d4"},"body":null,"isBase64Encoded":false}
2026-07-20T01:50:17.389000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 END RequestId: feab39a6-76a9-490f-9571-8b61ad5a2db2
2026-07-20T01:50:17.389000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 REPORT RequestId: feab39a6-76a9-490f-9571-8b61ad5a2db2	Duration: 55.11 ms	Billed Duration: 345 ms	Memory Size: 128 MB	Max Memory Used: 97 MB	Init Duration: 289.80 ms
2026-07-20T01:52:26.681000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 START RequestId: 9ddcf2de-1201-40bf-a649-9f736f467006 Version: $LATEST
2026-07-20T01:52:26.688000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:52:26.688Z	9ddcf2de-1201-40bf-a649-9f736f467006	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw","Host":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a5d7f5a-2703a62d161744c2657dc755","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw"],"Host":["uapov0k2d4.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a5d7f5a-2703a62d161744c2657dc755"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"Norrin"},"multiValueQueryStringParameters":{"name":["Norrin"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"lotoky","authorizer":{"claims":{"sub":"28414310-f071-701b-336a-55324d59b5bd","cognito:groups":"admin","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T","version":"2","client_id":"4hqt9ikctmesulmh0hbqbs00ta","origin_jti":"cbd790e9-4fff-4275-816f-86c0dc5b2f20","event_id":"b4f5ea41-f749-4512-b049-7d7b39f10b50","token_use":"access","scope":"rbac-api/admin openid rbac-api/user","auth_time":"1784510079","exp":"Mon Jul 20 02:14:39 UTC 2026","iat":"Mon Jul 20 01:14:39 UTC 2026","jti":"32c296ce-0752-4475-8cd0-d946eeb5f4a7","username":"admin.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"AyDWPHXEPHcEkgA=","requestTime":"20/Jul/2026:01:52:26 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"uapov0k2d4","requestTimeEpoch":1784512346612,"requestId":"1a0dca5b-5267-4844-a039-06f386b3f32d","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","deploymentId":"1hvxxe","apiId":"uapov0k2d4"},"body":null,"isBase64Encoded":false}
2026-07-20T01:52:27.549000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:52:27.549Z	9ddcf2de-1201-40bf-a649-9f736f467006	INFO	Response: {"message":"HELLO NORRIN FROM NODE!","groups":["admin"],"admin":true}
2026-07-20T01:52:27.589000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 END RequestId: 9ddcf2de-1201-40bf-a649-9f736f467006
2026-07-20T01:52:27.589000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 REPORT RequestId: 9ddcf2de-1201-40bf-a649-9f736f467006	Duration: 907.71 ms	Billed Duration: 908 ms	Memory Size: 128 MB	Max Memory Used: 97 MB
2026-07-20T01:55:58.702000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 START RequestId: c863c857-78f9-45d8-b079-4a5a04d1b332 Version: $LATEST
2026-07-20T01:55:58.703000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:55:58.703Z	c863c857-78f9-45d8-b079-4a5a04d1b332	INFO	Incoming event: {}
2026-07-20T01:55:58.730000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 END RequestId: c863c857-78f9-45d8-b079-4a5a04d1b332
2026-07-20T01:55:58.730000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 REPORT RequestId: c863c857-78f9-45d8-b079-4a5a04d1b332	Duration: 27.65 ms	Billed Duration: 28 ms	Memory Size: 128 MB	Max Memory Used: 97 MB
2026-07-20T01:56:21.934000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 START RequestId: 785725ab-be59-4a7d-8118-5c64d154f9a7 Version: $LATEST
2026-07-20T01:56:21.949000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:56:21.949Z	785725ab-be59-4a7d-8118-5c64d154f9a7	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw","Host":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a5d8045-67ddbe7a7a9c4f0e64d3e2dd","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyODQxNDMxMC1mMDcxLTcwMWItMzM2YS01NTMyNGQ1OWI1YmQiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9ja0pQbFB6MFQiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiI0aHF0OWlrY3RtZXN1bG1oMGhicWJzMDB0YSIsIm9yaWdpbl9qdGkiOiJjYmQ3OTBlOS00ZmZmLTQyNzUtODE2Zi04NmMwZGM1YjJmMjAiLCJldmVudF9pZCI6ImI0ZjVlYTQxLWY3NDktNDUxMi1iMDQ5LTdkN2IzOWYxMGI1MCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ1MTAwNzksImV4cCI6MTc4NDUxMzY3OSwiaWF0IjoxNzg0NTEwMDc5LCJqdGkiOiIzMmMyOTZjZS0wNzUyLTQ0NzUtOGNkMC1kOTQ2ZWViNWY0YTciLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.Jp7HjrPQEgyLfksSiDEpv_M2Ryw0SYci3Hko5IM6VRbWNUdbX60fElElaM0BzuJvJiayPf4Pzd8Iawho81XXw5FL4en9tOje3G3_0cLgHriTY7rXr8NswsIEU5G9oT9bJKFHXWhUNdsETiT_gqpS1E9WqpUsM1zVjwjevjWVAFcitRiUAaUJJY_ZMnCAzT2v_mm0aIVkCwJ74ZdhPpNkXOA7HptE8jpHDgeKAd6Jp2B_wA3yToDiZtbpIMbPPAazbi5kKNk_i6kqfRPfHObJdqZRpRFunwnKcRzDjCoaFeVkMEf2SLCqaJuG4ohjCJwIsYTk_mh7eEe2_moPI2JoSw"],"Host":["uapov0k2d4.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a5d8045-67ddbe7a7a9c4f0e64d3e2dd"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"theo"},"multiValueQueryStringParameters":{"name":["theo"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"lotoky","authorizer":{"claims":{"sub":"28414310-f071-701b-336a-55324d59b5bd","cognito:groups":"admin","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T","version":"2","client_id":"4hqt9ikctmesulmh0hbqbs00ta","origin_jti":"cbd790e9-4fff-4275-816f-86c0dc5b2f20","event_id":"b4f5ea41-f749-4512-b049-7d7b39f10b50","token_use":"access","scope":"rbac-api/admin openid rbac-api/user","auth_time":"1784510079","exp":"Mon Jul 20 02:14:39 UTC 2026","iat":"Mon Jul 20 01:14:39 UTC 2026","jti":"32c296ce-0752-4475-8cd0-d946eeb5f4a7","username":"admin.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"AyD6_FHMvHcECIA=","requestTime":"20/Jul/2026:01:56:21 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"uapov0k2d4","requestTimeEpoch":1784512581891,"requestId":"abe23b51-3a85-4167-851d-9ab66fc506b3","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","deploymentId":"1hvxxe","apiId":"uapov0k2d4"},"body":null,"isBase64Encoded":false}
2026-07-20T01:56:22.130000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:56:22.130Z	785725ab-be59-4a7d-8118-5c64d154f9a7	INFO	Response: {"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
2026-07-20T01:56:22.170000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 END RequestId: 785725ab-be59-4a7d-8118-5c64d154f9a7
2026-07-20T01:56:22.170000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 REPORT RequestId: 785725ab-be59-4a7d-8118-5c64d154f9a7	Duration: 235.33 ms	Billed Duration: 236 ms	Memory Size: 128 MB	Max Memory Used: 98 MB
2026-07-20T01:56:23.542000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 START RequestId: d0341980-6b50-4bae-a9c3-60b07f20e4fd Version: $LATEST
2026-07-20T01:56:23.543000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 2026-07-20T01:56:23.543Z	d0341980-6b50-4bae-a9c3-60b07f20e4fd	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA","Host":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a5d8047-0aa7c8b8021990b67b17371d","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJhVFVhRTQvWnY1SDZuOE9ZV0NnTEp4dlFCT2l3ZEtEd3FjU3ZTeWdWbzhzPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI2OGExYTNmMC1lMDExLTcwMDUtY2RkOS0zMmRjNGY0MTI3ZTUiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yX2NrSlBsUHowVCIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjRocXQ5aWtjdG1lc3VsbWgwaGJxYnMwMHRhIiwib3JpZ2luX2p0aSI6IjAxOGEyYTc0LTcxY2QtNDcxNC1hMmVhLTgzYTE0NjE2Y2M2NyIsImV2ZW50X2lkIjoiOTA1ZDAxMWUtZjhkNy00N2M1LWJhOTEtMTNhMWRlNDk0OGFmIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDUxMDkzMiwiZXhwIjoxNzg0NTE0NTMyLCJpYXQiOjE3ODQ1MTA5MzIsImp0aSI6IjU3MTk4MjVkLWNiNGMtNGU3NC04OWE0LTdkNDJlODBjYWRhNiIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.hPrktyo14VjlPiLII26mnvB21zCcoQCqW5QTbCS_KEdHyfzt2eRaRPCpNI5xk_ibva42kwwDOf8zcEr0_Gk4zlT6uWEdE03aJLYeNDhoFEKlgLJp0Z6tqTcN-nu-CCnz1gOmWxJgT6xkTzPXH6Ql2u4kIwv0H-vqOQSOm-6fOmhuAyrPLiKO8a79bdaz3O8GjgLgxZH8FIHpcjDHaRNUIxbaSYFBqmkz4Y6crDPmRHS7VsbX_vIDyRKICkEhWldCTX-_Xx-WoePkZBLKY_1v8NZomxpXRkljzlZVVh8fnNWG_uUrfEQhjhiP5Wh5PIigFaDjOMZsWHAv47aSlkqWnA"],"Host":["uapov0k2d4.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a5d8047-0aa7c8b8021990b67b17371d"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"lotoky","authorizer":{"claims":{"sub":"68a1a3f0-e011-7005-cdd9-32dc4f4127e5","cognito:groups":"user","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_ckJPlPz0T","version":"2","client_id":"4hqt9ikctmesulmh0hbqbs00ta","origin_jti":"018a2a74-71cd-4714-a2ea-83a14616cc67","event_id":"905d011e-f8d7-47c5-ba91-13a1de4948af","token_use":"access","scope":"openid rbac-api/user","auth_time":"1784510932","exp":"Mon Jul 20 02:28:52 UTC 2026","iat":"Mon Jul 20 01:28:52 UTC 2026","jti":"5719825d-cb4c-4e74-89a4-7d42e80cada6","username":"user.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"AyD7PEHSPHcEACg=","requestTime":"20/Jul/2026:01:56:23 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"uapov0k2d4","requestTimeEpoch":1784512583497,"requestId":"d0dad5d7-78da-411d-9e90-314b2614055c","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"uapov0k2d4.execute-api.us-west-2.amazonaws.com","deploymentId":"1hvxxe","apiId":"uapov0k2d4"},"body":null,"isBase64Encoded":false}
2026-07-20T01:56:23.544000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 END RequestId: d0341980-6b50-4bae-a9c3-60b07f20e4fd
2026-07-20T01:56:23.544000+00:00 2026/07/20/[$LATEST]d528b62f4c764a2f93068d0474f50ae8 REPORT RequestId: d0341980-6b50-4bae-a9c3-60b07f20e4fd	Duration: 1.52 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 98 MB
Checking API Gateway access logs...
2026-07-20T01:50:15.218000+00:00 ae862e76abfb8de2e734cc3e8d76ae59 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyDBtGT_vHcEQHA=","httpMethod":"GET","integrationLatency":"879","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"57021f9a-d6e4-441d-80b0-f3bfa7bbbc6c","requestTime":"20/Jul/2026:01:50:15 +0000","requestTimeEpoch":"1784512215218","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:52:25.639000+00:00 4de0ce218a16bcaf9682818f78861054 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyDWFELlvHcEEog=","httpMethod":"GET","integrationLatency":"404","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"ea33866b-abdf-4220-9175-3026f704a56f","requestTime":"20/Jul/2026:01:52:25 +0000","requestTimeEpoch":"1784512345639","resourcePath":"/PythonResource","responseLength":"100","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:16.570000+00:00 ec333b8baf8f8bf0fdfc8db364d30bc1 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"AyD6KEwwPHcEKxg=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"8db3b4dd-ecd5-436d-9eeb-a544e39d3e12","requestTime":"20/Jul/2026:01:56:16 +0000","requestTimeEpoch":"1784512576570","resourcePath":"/PythonResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:20.195000+00:00 43a62f41b29bab8726efc977b6351e9f {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyD6uGZKvHcEILw=","httpMethod":"GET","integrationLatency":"287","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"badc1f00-764a-4a04-8cc7-241caa19c7b8","requestTime":"20/Jul/2026:01:56:20 +0000","requestTimeEpoch":"1784512580195","resourcePath":"/PythonResource","responseLength":"98","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:22.975000+00:00 2d83a900a05eda1e07de4c3c9f737112 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyD7KHd7vHcEOQA=","httpMethod":"GET","integrationLatency":"11","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"9c807ecb-9643-4973-8e14-af75c44ddd82","requestTime":"20/Jul/2026:01:56:22 +0000","requestTimeEpoch":"1784512582975","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:24.202000+00:00 ccf08d090fcc59f7e49892490d5cfec3 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"AyD7XHOaPHcEuUw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"47568f50-74a6-4861-be4c-afed4e586f5a","requestTime":"20/Jul/2026:01:56:24 +0000","requestTimeEpoch":"1784512584202","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:25.286000+00:00 871541196800e613f0292328108fbde7 {"apiId":"d2zxhf2ieg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"AyD7hEUNvHcEh0Q=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"5699b8b9-b87b-4dd4-954b-61c277d34637","requestTime":"20/Jul/2026:01:56:25 +0000","requestTimeEpoch":"1784512585286","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:50:16.828000+00:00 f9de4f8d1fe5a8a9055c61bcb4b9146a {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyDB9HbGPHcEPBw=","httpMethod":"GET","integrationLatency":"527","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"723011d2-eb3a-4ea2-86b2-19533f6a05da","requestTime":"20/Jul/2026:01:50:16 +0000","requestTimeEpoch":"1784512216828","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:52:26.612000+00:00 d16c08e296e096c362d5242a910b1beb {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyDWPHXEPHcEkgA=","httpMethod":"GET","integrationLatency":"898","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"1a0dca5b-5267-4844-a039-06f386b3f32d","requestTime":"20/Jul/2026:01:52:26 +0000","requestTimeEpoch":"1784512346612","resourcePath":"/NodeResource","responseLength":"69","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:17.688000+00:00 8edc0889d3daa36340fe905a40bfacee {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"AyD6VFqGvHcEGBg=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"1462e2c4-eb2f-4a83-ae4c-573751ed9fbe","requestTime":"20/Jul/2026:01:56:17 +0000","requestTimeEpoch":"1784512577688","resourcePath":"/NodeResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:21.891000+00:00 cc6e49cc749f9ae38279af1fd0796f65 {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyD6_FHMvHcECIA=","httpMethod":"GET","integrationLatency":"251","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"abe23b51-3a85-4167-851d-9ab66fc506b3","requestTime":"20/Jul/2026:01:56:21 +0000","requestTimeEpoch":"1784512581891","resourcePath":"/NodeResource","responseLength":"67","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:23.497000+00:00 e2304a84f762cb2f83e66abd2dce317c {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"AyD7PEHSPHcEACg=","httpMethod":"GET","integrationLatency":"12","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"d0dad5d7-78da-411d-9e90-314b2614055c","requestTime":"20/Jul/2026:01:56:23 +0000","requestTimeEpoch":"1784512583497","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:24.718000+00:00 38d156163f9a9254c36e0ef50ecda738 {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"AyD7cFvTvHcEhoQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"2ecf95e3-d051-4b1f-8000-a7ba4a3d4ce8","requestTime":"20/Jul/2026:01:56:24 +0000","requestTimeEpoch":"1784512584718","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-20T01:56:25.709000+00:00 fea62625e0886f93a7a2b55e3c83df06 {"apiId":"uapov0k2d4","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"AyD7mHXQvHcEMtA=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"61b545e4-5ff1-4c83-b126-047fab533ff8","requestTime":"20/Jul/2026:01:56:25 +0000","requestTimeEpoch":"1784512585709","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/a8a17ae5-3d72-4980-9f20-befa8a11a57e"}
2026-07-19 15:53:10          0 AWSLogs/015195098145/
2026-07-19 16:07:07        951 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/19/23/00/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260719T2300Z_eeb047b4.log.gz
2026-07-19 16:12:07        969 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/19/23/05/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260719T2305Z_9bd93792.log.gz
2026-07-19 18:57:07       1776 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/20/01/50/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260720T0150Z_736c6053.log.gz
2026-07-19 18:52:07       1765 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/20/01/50/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260720T0150Z_7ac61141.log.gz
2026-07-19 18:57:07       3308 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/20/01/55/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260720T0155Z_a55ad9c1.log.gz

## Script Exit Summary

- Checks run: 10
- Failures: 0
- Skipped: 0
- Result: PASS

Skipping WAF CloudWatch logs check because waf_log_group output is N/A.
Wrote summary document: /c/Users/John Sweeney/aws/lambda/SEIR-Serverless-SOAR/Reports/rbac_test_report.md
RBAC_TEST_RESULT=PASS checks=10 failures=0 skipped=0
