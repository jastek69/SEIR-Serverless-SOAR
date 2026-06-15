# RBAC and WAF Test Report

- Generated (UTC): 2026-06-15T05:11:49Z
- Region: us-west-2
- Python API: https://tgoutn4oje.execute-api.us-west-2.amazonaws.com/prod
- Node API: https://zjiqu82rrc.execute-api.us-west-2.amazonaws.com/prod

Writing full run transcript to: /c/Users/John Sweeney/aws/lambda/lambda-skel/lambda-restapi-rbac-bedrock/Reports/rbac_test_report.md
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
Testing script execution completed. Check the generated reports in /c/Users/John Sweeney/aws/lambda/lambda-skel/lambda-restapi-rbac-bedrock/Reports and the Lambda responses in response.json, node_response.json, and invalid_response.json for results.
testing Negative auth scenario with Node Lambda function...
HTTP/1.1 401 Unauthorized
Date: Mon, 15 Jun 2026 05:12:42 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: b6c062ad-3121-4192-be7a-d9d8429071c4
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: e_J3pGDNPHcEqag=

{"message":"Unauthorized"}
HTTP/1.1 401 Unauthorized
Date: Mon, 15 Jun 2026 05:12:43 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: d861a90f-e892-4db5-826b-7eee3ed714d2
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: e_J30GqCPHcES1g=

{"message":"Unauthorized"}
PASS: Python no-token auth (expected=401 actual=401)
PASS: Node no-token auth (expected=401 actual=401)
Positive auth test (valid token)
HTTP/1.1 200 OK
Date: Mon, 15 Jun 2026 05:12:43 GMT
Content-Type: application/json
Content-Length: 98
Connection: keep-alive
x-amzn-RequestId: 3132a6d1-8d30-4677-b07e-f4dcbf556ebd
x-amz-apigw-id: e_J36EirPHcEZgQ=
X-Amzn-Trace-Id: Root=1-6a2f89cb-6cc5a64e69701adb364652ba;Parent=56ba1225eb861edd;Sampled=0;Lineage=1:315d35d1:0

{"message": "Hello theo from Python!", "timestamp": "2026-06-15T05:12:43.944580", "role": "admin"}
HTTP/1.1 200 OK
Date: Mon, 15 Jun 2026 05:12:44 GMT
Content-Type: application/json
Content-Length: 67
Connection: keep-alive
x-amzn-RequestId: a31fdb34-84a0-4db3-9d38-f7b916d471ab
x-amz-apigw-id: e_J4AGE9vHcEafA=
X-Amzn-Trace-Id: Root=1-6a2f89cc-6e7ce5b6274e5f4b582b3f96;Parent=76b789e736bef79d;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
PASS: Python admin auth (expected=200 actual=200)
PASS: Node admin auth (expected=200 actual=200)
RBAC deny test with non-admin token (expected: 403)
HTTP/1.1 403 Forbidden
Date: Mon, 15 Jun 2026 05:12:44 GMT
Content-Type: application/json
Content-Length: 50
Connection: keep-alive
x-amzn-RequestId: 32a6c92e-fbf7-47e0-9f6f-01a9ecec1b61
x-amz-apigw-id: e_J4FFBIPHcENGA=
X-Amzn-Trace-Id: Root=1-6a2f89cc-2f8709d45f7abc8031dcb1d8;Parent=4c0d0a714731745e;Sampled=0;Lineage=1:315d35d1:0

{"message": "Access denied: admin group required"}
HTTP/1.1 403 Forbidden
Date: Mon, 15 Jun 2026 05:12:45 GMT
Content-Type: application/json
Content-Length: 49
Connection: keep-alive
x-amzn-RequestId: 33768996-d6ba-4b38-b731-2c79b7a0560d
x-amz-apigw-id: e_J4JGNzvHcEHCA=
X-Amzn-Trace-Id: Root=1-6a2f89cd-4790d96c4f6a5b367b561a66;Parent=347d6c75e7f76b03;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"Access denied: admin group required"}
PASS: Python RBAC deny (expected=403 actual=403)
PASS: Node RBAC deny (expected=403 actual=403)
WAF strict block test (XSS payload) - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Mon, 15 Jun 2026 05:12:45 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 6d098c00-0d76-44e2-8a4b-e2018b05c16c
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: e_J4OGvoPHcEMVw=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Mon, 15 Jun 2026 05:12:46 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 14541bd5-1290-4887-a45e-c44b42faf243
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: e_J4SHS7vHcEXrQ=

{"message":"Forbidden"}
PASS: Python WAF strict XSS (expected=403 actual=403)
PASS: Node WAF strict XSS (expected=403 actual=403)
Strict WAF summary: Python=403 Node=403 Result=PASS
## WAF Strict Block Result

- Python XSS status: 403
- Node XSS status: 403
- Result: PASS

WAF informational SQLi-style test - expected: 403 or 200 depending on managed rules
HTTP/1.1 200 OK
Date: Mon, 15 Jun 2026 05:12:46 GMT
Content-Type: application/json
Content-Length: 111
Connection: keep-alive
x-amzn-RequestId: 6b0fa3da-f2db-43ab-9472-68dc46c285ac
x-amz-apigw-id: e_J4WGS0vHcEPoQ=
X-Amzn-Trace-Id: Root=1-6a2f89ce-15fe3db75754b72b65f167e7;Parent=6d1c2ef220bcc488;Sampled=0;Lineage=1:315d35d1:0

{"message": "Hello taaops' OR '1'='1 from Python!", "timestamp": "2026-06-15T05:12:46.696444", "role": "admin"}
HTTP/1.1 200 OK
Date: Mon, 15 Jun 2026 05:12:47 GMT
Content-Type: application/json
Content-Length: 80
Connection: keep-alive
x-amzn-RequestId: 8a2eda3d-3f06-4cad-b8e5-28144a2e5f29
x-amz-apigw-id: e_J4cEpBvHcEYtg=
X-Amzn-Trace-Id: Root=1-6a2f89cf-5aff4baf10481fcf0efda9b1;Parent=673089ea63ef5092;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"HELLO TAAOPS' OR '1'='1 FROM NODE!","groups":["admin"],"admin":true}
## WAF Informational SQLi-style Result

- Python SQLi-style status: 200
- Node SQLi-style status: 200
- Interpretation: 403 indicates blocked; 200 indicates allowed by current managed rules.

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
        "CreationDateTime": "2026-06-14T11:51:36.234000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 514,
        "ItemCount": 2,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking",
        "TableId": "f23a014e-57a4-4761-b5e8-5fce366eb931",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-06-14T11:51:36.234000-07:00"
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
                "IndexSizeBytes": 514,
                "ItemCount": 2,
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
                "IndexSizeBytes": 514,
                "ItemCount": 2,
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
                "IndexSizeBytes": 514,
                "ItemCount": 2,
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
        "CreationDateTime": "2026-06-14T11:51:36.230000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-revocation",
        "TableId": "371e87b3-e319-435e-af3e-7aca711ef367",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-06-14T11:51:36.230000-07:00"
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
        "CreationDate": "2026-06-14T11:53:03.706000-07:00",
        "GroupName": "default",
        "LastModificationDate": "2026-06-14T11:53:03.706000-07:00",
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
    "CreationDate": "2026-06-14T11:53:03.706000-07:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-06-14T11:53:03.706000-07:00",
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
2026-06-15T05:11:53.396000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 INIT_START Runtime Version: python:3.9.v133	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:b46f7bc0f3da8071d1b824471f2c69c8766b756b827eb0455d2118c622ae7bcf
2026-06-15T05:11:53.525000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 START RequestId: 31f431ce-8260-4f4e-87ed-8c2df474e2bd Version: $LATEST
2026-06-15T05:11:53.526000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Incoming event: {}
2026-06-15T05:11:53.527000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 END RequestId: 31f431ce-8260-4f4e-87ed-8c2df474e2bd
2026-06-15T05:11:53.537000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 REPORT RequestId: 31f431ce-8260-4f4e-87ed-8c2df474e2bd	Duration: 1.88 ms	Billed Duration: 123 ms	Memory Size: 128 MB	Max Memory Used: 31 MB	Init Duration: 121.11 ms
2026-06-15T05:12:00.426000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 START RequestId: 1a4e351f-908b-4d1b-95dd-c9869803b3ba Version: $LATEST
2026-06-15T05:12:00.426000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Incoming event: {}
2026-06-15T05:12:00.427000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 END RequestId: 1a4e351f-908b-4d1b-95dd-c9869803b3ba
2026-06-15T05:12:00.427000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 REPORT RequestId: 1a4e351f-908b-4d1b-95dd-c9869803b3ba	Duration: 1.29 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 31 MB
2026-06-15T05:12:43.944000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 START RequestId: f4d95f4e-0430-44e3-937a-e4e535635d3d Version: $LATEST
2026-06-15T05:12:43.946000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw", "Host": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a2f89cb-6cc5a64e69701adb364652ba", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw"], "Host": ["tgoutn4oje.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a2f89cb-6cc5a64e69701adb364652ba"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "theo"}, "multiValueQueryStringParameters": {"name": ["theo"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "5gxy8a", "authorizer": {"claims": {"sub": "58e18350-4001-704c-0029-30a8ec351fa0", "cognito:groups": "admin", "email_verified": "true", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka", "cognito:username": "adminii.test", "origin_jti": "39c55a59-abc3-4b17-9c4f-b0b86b291013", "aud": "ifgmi34q9at5m8j6otoh3ur1h", "event_id": "435aec7a-caa9-478a-b711-001d9c48d868", "token_use": "id", "auth_time": "1781499381", "exp": "Mon Jun 15 05:56:21 UTC 2026", "iat": "Mon Jun 15 04:56:21 UTC 2026", "jti": "e2826537-2570-4200-a45c-f1f8b331023b", "email": "admin.jastek.sweeney@gmail.com"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "e_J36EirPHcEZgQ=", "requestTime": "15/Jun/2026:05:12:43 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "tgoutn4oje", "requestTimeEpoch": 1781500363847, "requestId": "3132a6d1-8d30-4677-b07e-f4dcbf556ebd", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "deploymentId": "irvq3n", "apiId": "tgoutn4oje"}, "body": null, "isBase64Encoded": false}
2026-06-15T05:12:43.946000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Response: {"message": "Hello theo from Python!", "timestamp": "2026-06-15T05:12:43.944580", "role": "admin"}
2026-06-15T05:12:43.946000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 END RequestId: f4d95f4e-0430-44e3-937a-e4e535635d3d
2026-06-15T05:12:43.946000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 REPORT RequestId: f4d95f4e-0430-44e3-937a-e4e535635d3d	Duration: 1.56 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 31 MB
2026-06-15T05:12:44.986000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 START RequestId: 70b2150f-d0ca-4857-808b-d5bc1d7e2407 Version: $LATEST
2026-06-15T05:12:44.986000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIwODcxNzM3MC0wMGUxLTcwMTItNDJjMy1jNDlmZDc3MjFkNmYiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9VeFR0U0Roa2EiLCJjb2duaXRvOnVzZXJuYW1lIjoidXNlcmlpLnRlc3QiLCJvcmlnaW5fanRpIjoiMjM3Y2MxYzctMWFiYi00MmQ0LWE2MjktMGZlNWFlYTFkMGUzIiwiYXVkIjoiaWZnbWkzNHE5YXQ1bThqNm90b2gzdXIxaCIsImV2ZW50X2lkIjoiMTRjZjk4ZWQtNmY5OS00NzBiLWE3MDMtNjJiMzA3YmRkMGJlIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3ODE1MDAyNTMsImV4cCI6MTc4MTUwMzg1MywiaWF0IjoxNzgxNTAwMjUzLCJqdGkiOiI3ZTVlYmM1OS03MzdjLTQ3YjEtYjQyOS0yZDMxNjM3MTY0Y2IiLCJlbWFpbCI6InVzZXIuamFzdGVrLmRldm9wc0BnbWFpbC5jb20ifQ.CsTK_GRuXv3edcG4YrGhYGCxW4I0D8ITjwtDW3AYmR29BHhM76u2B6vV2-eZrfYL1gz8oNYPAMODkUGJX3b0YdDnoHgs8zTiYbjgTuA_bqi4QDowJT72ZTVKEtQnO9mQmwukh5_Q3Scr2oDWNxE1fz6wZNcrEZAnP0Nnq6VvaRVzqMbSUZC_FtLgNprLEi0HQ9U9Wh6V4AKh4Y9-z-NRaUN5_5DxZXhM72IrwJsmGlvduKMQU9eGYtH6Yp5hFHA5-SWo3F_SbRSbcRqU53MN2uJvXqu_J1kgAm85LJnXfsAAn_0ejyv-cCGpbWSgtyaymbq49mDGs72_T-cUI2YBfw", "Host": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a2f89cc-2f8709d45f7abc8031dcb1d8", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIwODcxNzM3MC0wMGUxLTcwMTItNDJjMy1jNDlmZDc3MjFkNmYiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9VeFR0U0Roa2EiLCJjb2duaXRvOnVzZXJuYW1lIjoidXNlcmlpLnRlc3QiLCJvcmlnaW5fanRpIjoiMjM3Y2MxYzctMWFiYi00MmQ0LWE2MjktMGZlNWFlYTFkMGUzIiwiYXVkIjoiaWZnbWkzNHE5YXQ1bThqNm90b2gzdXIxaCIsImV2ZW50X2lkIjoiMTRjZjk4ZWQtNmY5OS00NzBiLWE3MDMtNjJiMzA3YmRkMGJlIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3ODE1MDAyNTMsImV4cCI6MTc4MTUwMzg1MywiaWF0IjoxNzgxNTAwMjUzLCJqdGkiOiI3ZTVlYmM1OS03MzdjLTQ3YjEtYjQyOS0yZDMxNjM3MTY0Y2IiLCJlbWFpbCI6InVzZXIuamFzdGVrLmRldm9wc0BnbWFpbC5jb20ifQ.CsTK_GRuXv3edcG4YrGhYGCxW4I0D8ITjwtDW3AYmR29BHhM76u2B6vV2-eZrfYL1gz8oNYPAMODkUGJX3b0YdDnoHgs8zTiYbjgTuA_bqi4QDowJT72ZTVKEtQnO9mQmwukh5_Q3Scr2oDWNxE1fz6wZNcrEZAnP0Nnq6VvaRVzqMbSUZC_FtLgNprLEi0HQ9U9Wh6V4AKh4Y9-z-NRaUN5_5DxZXhM72IrwJsmGlvduKMQU9eGYtH6Yp5hFHA5-SWo3F_SbRSbcRqU53MN2uJvXqu_J1kgAm85LJnXfsAAn_0ejyv-cCGpbWSgtyaymbq49mDGs72_T-cUI2YBfw"], "Host": ["tgoutn4oje.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a2f89cc-2f8709d45f7abc8031dcb1d8"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "5gxy8a", "authorizer": {"claims": {"sub": "08717370-00e1-7012-42c3-c49fd7721d6f", "cognito:groups": "user", "email_verified": "true", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka", "cognito:username": "userii.test", "origin_jti": "237cc1c7-1abb-42d4-a629-0fe5aea1d0e3", "aud": "ifgmi34q9at5m8j6otoh3ur1h", "event_id": "14cf98ed-6f99-470b-a703-62b307bdd0be", "token_use": "id", "auth_time": "1781500253", "exp": "Mon Jun 15 06:10:53 UTC 2026", "iat": "Mon Jun 15 05:10:53 UTC 2026", "jti": "7e5ebc59-737c-47b1-b429-2d31637164cb", "email": "user.jastek.devops@gmail.com"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "e_J4FFBIPHcENGA=", "requestTime": "15/Jun/2026:05:12:44 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "tgoutn4oje", "requestTimeEpoch": 1781500364933, "requestId": "32a6c92e-fbf7-47e0-9f6f-01a9ecec1b61", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "deploymentId": "irvq3n", "apiId": "tgoutn4oje"}, "body": null, "isBase64Encoded": false}
2026-06-15T05:12:44.987000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 END RequestId: 70b2150f-d0ca-4857-808b-d5bc1d7e2407
2026-06-15T05:12:44.987000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 REPORT RequestId: 70b2150f-d0ca-4857-808b-d5bc1d7e2407	Duration: 1.40 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 31 MB
2026-06-15T05:12:46.695000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 START RequestId: 829d610f-130f-47d9-afc4-3707011a4eb9 Version: $LATEST
2026-06-15T05:12:46.696000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw", "Host": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a2f89ce-15fe3db75754b72b65f167e7", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw"], "Host": ["tgoutn4oje.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a2f89ce-15fe3db75754b72b65f167e7"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "taaops' OR '1'='1"}, "multiValueQueryStringParameters": {"name": ["taaops' OR '1'='1"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "5gxy8a", "authorizer": {"claims": {"sub": "58e18350-4001-704c-0029-30a8ec351fa0", "cognito:groups": "admin", "email_verified": "true", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka", "cognito:username": "adminii.test", "origin_jti": "39c55a59-abc3-4b17-9c4f-b0b86b291013", "aud": "ifgmi34q9at5m8j6otoh3ur1h", "event_id": "435aec7a-caa9-478a-b711-001d9c48d868", "token_use": "id", "auth_time": "1781499381", "exp": "Mon Jun 15 05:56:21 UTC 2026", "iat": "Mon Jun 15 04:56:21 UTC 2026", "jti": "e2826537-2570-4200-a45c-f1f8b331023b", "email": "admin.jastek.sweeney@gmail.com"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "e_J4WGS0vHcEPoQ=", "requestTime": "15/Jun/2026:05:12:46 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "tgoutn4oje", "requestTimeEpoch": 1781500366642, "requestId": "6b0fa3da-f2db-43ab-9472-68dc46c285ac", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "tgoutn4oje.execute-api.us-west-2.amazonaws.com", "deploymentId": "irvq3n", "apiId": "tgoutn4oje"}, "body": null, "isBase64Encoded": false}
2026-06-15T05:12:46.696000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 Response: {"message": "Hello taaops' OR '1'='1 from Python!", "timestamp": "2026-06-15T05:12:46.696444", "role": "admin"}
2026-06-15T05:12:46.697000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 END RequestId: 829d610f-130f-47d9-afc4-3707011a4eb9
2026-06-15T05:12:46.697000+00:00 2026/06/15/[$LATEST]bcfb0f0300a44c9bba473d6d24894e70 REPORT RequestId: 829d610f-130f-47d9-afc4-3707011a4eb9	Duration: 1.45 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 31 MB
2026-06-15T05:11:56.877000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 INIT_START Runtime Version: nodejs:24.v41	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:ace575f77c462dad266ad34d6f4479819cfc812427752cd97a71c239753c23cb
2026-06-15T05:11:57.043000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 START RequestId: 581680ad-d7b2-45c3-9a7b-8a947fabf3b2 Version: $LATEST
2026-06-15T05:11:57.045000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:11:57.045Z	581680ad-d7b2-45c3-9a7b-8a947fabf3b2	INFO	Incoming event: {}
2026-06-15T05:11:57.106000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 END RequestId: 581680ad-d7b2-45c3-9a7b-8a947fabf3b2
2026-06-15T05:11:57.106000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 REPORT RequestId: 581680ad-d7b2-45c3-9a7b-8a947fabf3b2	Duration: 62.14 ms	Billed Duration: 225 ms	Memory Size: 128 MB	Max Memory Used: 78 MB	Init Duration: 162.08 ms
2026-06-15T05:12:44.459000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 START RequestId: 58d2d822-81f4-4794-a209-411d0a1c7099 Version: $LATEST
2026-06-15T05:12:44.460000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:12:44.460Z	58d2d822-81f4-4794-a209-411d0a1c7099	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw","Host":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a2f89cc-6e7ce5b6274e5f4b582b3f96","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw"],"Host":["zjiqu82rrc.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a2f89cc-6e7ce5b6274e5f4b582b3f96"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"theo"},"multiValueQueryStringParameters":{"name":["theo"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"h7yacb","authorizer":{"claims":{"sub":"58e18350-4001-704c-0029-30a8ec351fa0","cognito:groups":"admin","email_verified":"true","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka","cognito:username":"adminii.test","origin_jti":"39c55a59-abc3-4b17-9c4f-b0b86b291013","aud":"ifgmi34q9at5m8j6otoh3ur1h","event_id":"435aec7a-caa9-478a-b711-001d9c48d868","token_use":"id","auth_time":"1781499381","exp":"Mon Jun 15 05:56:21 UTC 2026","iat":"Mon Jun 15 04:56:21 UTC 2026","jti":"e2826537-2570-4200-a45c-f1f8b331023b","email":"admin.jastek.sweeney@gmail.com"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"e_J4AGE9vHcEafA=","requestTime":"15/Jun/2026:05:12:44 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"zjiqu82rrc","requestTimeEpoch":1781500364402,"requestId":"a31fdb34-84a0-4db3-9d38-f7b916d471ab","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","deploymentId":"4rz8il","apiId":"zjiqu82rrc"},"body":null,"isBase64Encoded":false}
2026-06-15T05:12:44.461000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:12:44.461Z	58d2d822-81f4-4794-a209-411d0a1c7099	INFO	Response: {"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
2026-06-15T05:12:44.465000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 END RequestId: 58d2d822-81f4-4794-a209-411d0a1c7099
2026-06-15T05:12:44.465000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 REPORT RequestId: 58d2d822-81f4-4794-a209-411d0a1c7099	Duration: 4.73 ms	Billed Duration: 5 ms	Memory Size: 128 MB	Max Memory Used: 78 MB
2026-06-15T05:12:45.402000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:12:45.402Z	9989ee37-4dda-49c6-bb34-470e465ede80	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIwODcxNzM3MC0wMGUxLTcwMTItNDJjMy1jNDlmZDc3MjFkNmYiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9VeFR0U0Roa2EiLCJjb2duaXRvOnVzZXJuYW1lIjoidXNlcmlpLnRlc3QiLCJvcmlnaW5fanRpIjoiMjM3Y2MxYzctMWFiYi00MmQ0LWE2MjktMGZlNWFlYTFkMGUzIiwiYXVkIjoiaWZnbWkzNHE5YXQ1bThqNm90b2gzdXIxaCIsImV2ZW50X2lkIjoiMTRjZjk4ZWQtNmY5OS00NzBiLWE3MDMtNjJiMzA3YmRkMGJlIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3ODE1MDAyNTMsImV4cCI6MTc4MTUwMzg1MywiaWF0IjoxNzgxNTAwMjUzLCJqdGkiOiI3ZTVlYmM1OS03MzdjLTQ3YjEtYjQyOS0yZDMxNjM3MTY0Y2IiLCJlbWFpbCI6InVzZXIuamFzdGVrLmRldm9wc0BnbWFpbC5jb20ifQ.CsTK_GRuXv3edcG4YrGhYGCxW4I0D8ITjwtDW3AYmR29BHhM76u2B6vV2-eZrfYL1gz8oNYPAMODkUGJX3b0YdDnoHgs8zTiYbjgTuA_bqi4QDowJT72ZTVKEtQnO9mQmwukh5_Q3Scr2oDWNxE1fz6wZNcrEZAnP0Nnq6VvaRVzqMbSUZC_FtLgNprLEi0HQ9U9Wh6V4AKh4Y9-z-NRaUN5_5DxZXhM72IrwJsmGlvduKMQU9eGYtH6Yp5hFHA5-SWo3F_SbRSbcRqU53MN2uJvXqu_J1kgAm85LJnXfsAAn_0ejyv-cCGpbWSgtyaymbq49mDGs72_T-cUI2YBfw","Host":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a2f89cd-4790d96c4f6a5b367b561a66","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIwODcxNzM3MC0wMGUxLTcwMTItNDJjMy1jNDlmZDc3MjFkNmYiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl9VeFR0U0Roa2EiLCJjb2duaXRvOnVzZXJuYW1lIjoidXNlcmlpLnRlc3QiLCJvcmlnaW5fanRpIjoiMjM3Y2MxYzctMWFiYi00MmQ0LWE2MjktMGZlNWFlYTFkMGUzIiwiYXVkIjoiaWZnbWkzNHE5YXQ1bThqNm90b2gzdXIxaCIsImV2ZW50X2lkIjoiMTRjZjk4ZWQtNmY5OS00NzBiLWE3MDMtNjJiMzA3YmRkMGJlIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3ODE1MDAyNTMsImV4cCI6MTc4MTUwMzg1MywiaWF0IjoxNzgxNTAwMjUzLCJqdGkiOiI3ZTVlYmM1OS03MzdjLTQ3YjEtYjQyOS0yZDMxNjM3MTY0Y2IiLCJlbWFpbCI6InVzZXIuamFzdGVrLmRldm9wc0BnbWFpbC5jb20ifQ.CsTK_GRuXv3edcG4YrGhYGCxW4I0D8ITjwtDW3AYmR29BHhM76u2B6vV2-eZrfYL1gz8oNYPAMODkUGJX3b0YdDnoHgs8zTiYbjgTuA_bqi4QDowJT72ZTVKEtQnO9mQmwukh5_Q3Scr2oDWNxE1fz6wZNcrEZAnP0Nnq6VvaRVzqMbSUZC_FtLgNprLEi0HQ9U9Wh6V4AKh4Y9-z-NRaUN5_5DxZXhM72IrwJsmGlvduKMQU9eGYtH6Yp5hFHA5-SWo3F_SbRSbcRqU53MN2uJvXqu_J1kgAm85LJnXfsAAn_0ejyv-cCGpbWSgtyaymbq49mDGs72_T-cUI2YBfw"],"Host":["zjiqu82rrc.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a2f89cd-4790d96c4f6a5b367b561a66"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"h7yacb","authorizer":{"claims":{"sub":"08717370-00e1-7012-42c3-c49fd7721d6f","cognito:groups":"user","email_verified":"true","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka","cognito:username":"userii.test","origin_jti":"237cc1c7-1abb-42d4-a629-0fe5aea1d0e3","aud":"ifgmi34q9at5m8j6otoh3ur1h","event_id":"14cf98ed-6f99-470b-a703-62b307bdd0be","token_use":"id","auth_time":"1781500253","exp":"Mon Jun 15 06:10:53 UTC 2026","iat":"Mon Jun 15 05:10:53 UTC 2026","jti":"7e5ebc59-737c-47b1-b429-2d31637164cb","email":"user.jastek.devops@gmail.com"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"e_J4JGNzvHcEHCA=","requestTime":"15/Jun/2026:05:12:45 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"zjiqu82rrc","requestTimeEpoch":1781500365368,"requestId":"33768996-d6ba-4b38-b731-2c79b7a0560d","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","deploymentId":"4rz8il","apiId":"zjiqu82rrc"},"body":null,"isBase64Encoded":false}
2026-06-15T05:12:45.402000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 START RequestId: 9989ee37-4dda-49c6-bb34-470e465ede80 Version: $LATEST
2026-06-15T05:12:45.404000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 END RequestId: 9989ee37-4dda-49c6-bb34-470e465ede80
2026-06-15T05:12:45.404000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 REPORT RequestId: 9989ee37-4dda-49c6-bb34-470e465ede80	Duration: 2.04 ms	Billed Duration: 3 ms	Memory Size: 128 MB	Max Memory Used: 78 MB
2026-06-15T05:12:47.252000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:12:47.252Z	dedba467-d1ce-4cb4-bb8e-0832a3047e67	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw","Host":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a2f89cf-5aff4baf10481fcf0efda9b1","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJUVHpST053Wm9wSzdGK2JyWmJMT2k4eGRLbnJ3NUtNb01LS0F6QzZFYjR3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxODM1MC00MDAxLTcwNGMtMDAyOS0zMGE4ZWMzNTFmYTAiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9jb2duaXRvLWlkcC51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS91cy13ZXN0LTJfVXhUdFNEaGthIiwiY29nbml0bzp1c2VybmFtZSI6ImFkbWluaWkudGVzdCIsIm9yaWdpbl9qdGkiOiIzOWM1NWE1OS1hYmMzLTRiMTctOWM0Zi1iMGI4NmIyOTEwMTMiLCJhdWQiOiJpZmdtaTM0cTlhdDVtOGo2b3RvaDN1cjFoIiwiZXZlbnRfaWQiOiI0MzVhZWM3YS1jYWE5LTQ3OGEtYjcxMS0wMDFkOWM0OGQ4NjgiLCJ0b2tlbl91c2UiOiJpZCIsImF1dGhfdGltZSI6MTc4MTQ5OTM4MSwiZXhwIjoxNzgxNTAyOTgxLCJpYXQiOjE3ODE0OTkzODEsImp0aSI6ImUyODI2NTM3LTI1NzAtNDIwMC1hNDVjLWYxZjhiMzMxMDIzYiIsImVtYWlsIjoiYWRtaW4uamFzdGVrLnN3ZWVuZXlAZ21haWwuY29tIn0.zv0ADbpG-D0IZ95kW6V8tmL5rhVAjzNlCxdTqBN_GoiZ9M_E57laE9KMJAHG4Ob_qsxHtB-OVjlgzE-kkdCwFKz1p6Rcfla127kc6cvQmFRzsx-mYFPDb90x3t41KLATwvzc3UsORmhzRPhl3jG-OQ-E-BxdM0H9V3gPXNrOWX9bu6Sn96ZcvMUNtBTzMOuzu-KXGjArfI-_C1Sn95Zj7H2RoBgmkht38g6rh9Bklt6faGAn1-xOaIv8-DB2PHGWn15sTB5367OfnaKzkyRLkioKRqIQwMo330UsmSqNf5puKMpalmlvKZBTer0IRBztq60yuWe6ZC4DwQx-UBsJQw"],"Host":["zjiqu82rrc.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a2f89cf-5aff4baf10481fcf0efda9b1"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"taaops' OR '1'='1"},"multiValueQueryStringParameters":{"name":["taaops' OR '1'='1"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"h7yacb","authorizer":{"claims":{"sub":"58e18350-4001-704c-0029-30a8ec351fa0","cognito:groups":"admin","email_verified":"true","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_UxTtSDhka","cognito:username":"adminii.test","origin_jti":"39c55a59-abc3-4b17-9c4f-b0b86b291013","aud":"ifgmi34q9at5m8j6otoh3ur1h","event_id":"435aec7a-caa9-478a-b711-001d9c48d868","token_use":"id","auth_time":"1781499381","exp":"Mon Jun 15 05:56:21 UTC 2026","iat":"Mon Jun 15 04:56:21 UTC 2026","jti":"e2826537-2570-4200-a45c-f1f8b331023b","email":"admin.jastek.sweeney@gmail.com"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"e_J4cEpBvHcEYtg=","requestTime":"15/Jun/2026:05:12:47 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"zjiqu82rrc","requestTimeEpoch":1781500367201,"requestId":"8a2eda3d-3f06-4cad-b8e5-28144a2e5f29","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"zjiqu82rrc.execute-api.us-west-2.amazonaws.com","deploymentId":"4rz8il","apiId":"zjiqu82rrc"},"body":null,"isBase64Encoded":false}
2026-06-15T05:12:47.252000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 START RequestId: dedba467-d1ce-4cb4-bb8e-0832a3047e67 Version: $LATEST
2026-06-15T05:12:47.253000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 2026-06-15T05:12:47.253Z	dedba467-d1ce-4cb4-bb8e-0832a3047e67	INFO	Response: {"message":"HELLO TAAOPS' OR '1'='1 FROM NODE!","groups":["admin"],"admin":true}
2026-06-15T05:12:47.265000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 END RequestId: dedba467-d1ce-4cb4-bb8e-0832a3047e67
2026-06-15T05:12:47.265000+00:00 2026/06/15/[$LATEST]5e1bbb3a52d148acb53e671c126fdac0 REPORT RequestId: dedba467-d1ce-4cb4-bb8e-0832a3047e67	Duration: 12.57 ms	Billed Duration: 13 ms	Memory Size: 128 MB	Max Memory Used: 78 MB
Checking API Gateway access logs...
2026-06-15T05:12:42.146000+00:00 a5d703ebd7d8d93ca5b4ca2cc0ef3d8a {"apiId":"tgoutn4oje","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"e_J3pGDNPHcEqag=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"b6c062ad-3121-4192-be7a-d9d8429071c4","requestTime":"15/Jun/2026:05:12:42 +0000","requestTimeEpoch":"1781500362146","resourcePath":"/PythonResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"7","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:43.847000+00:00 ffb8e7c5b01d382a8d5d038cfc8fe530 {"apiId":"tgoutn4oje","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J36EirPHcEZgQ=","httpMethod":"GET","integrationLatency":"26","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"3132a6d1-8d30-4677-b07e-f4dcbf556ebd","requestTime":"15/Jun/2026:05:12:43 +0000","requestTimeEpoch":"1781500363847","resourcePath":"/PythonResource","responseLength":"98","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:44.933000+00:00 1d8f34b579290c07fa07bdb8f9332f1c {"apiId":"tgoutn4oje","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J4FFBIPHcENGA=","httpMethod":"GET","integrationLatency":"13","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"32a6c92e-fbf7-47e0-9f6f-01a9ecec1b61","requestTime":"15/Jun/2026:05:12:44 +0000","requestTimeEpoch":"1781500364933","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:45.822000+00:00 379c3984d4ad6b681bca2699d79c49bd {"apiId":"tgoutn4oje","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"e_J4OGvoPHcEMVw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"6d098c00-0d76-44e2-8a4b-e2018b05c16c","requestTime":"15/Jun/2026:05:12:45 +0000","requestTimeEpoch":"1781500365822","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:46.642000+00:00 99fe33520214927e3175b5635313f3bf {"apiId":"tgoutn4oje","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J4WGS0vHcEPoQ=","httpMethod":"GET","integrationLatency":"21","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"6b0fa3da-f2db-43ab-9472-68dc46c285ac","requestTime":"15/Jun/2026:05:12:46 +0000","requestTimeEpoch":"1781500366642","resourcePath":"/PythonResource","responseLength":"111","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:43.249000+00:00 a59f66c92cebc4cbb164fff61b1ba658 {"apiId":"zjiqu82rrc","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"e_J30GqCPHcES1g=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"d861a90f-e892-4db5-826b-7eee3ed714d2","requestTime":"15/Jun/2026:05:12:43 +0000","requestTimeEpoch":"1781500363249","resourcePath":"/NodeResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:44.402000+00:00 7c49b2bf7db6b2a6af33de618c01bf7c {"apiId":"zjiqu82rrc","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J4AGE9vHcEafA=","httpMethod":"GET","integrationLatency":"21","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"a31fdb34-84a0-4db3-9d38-f7b916d471ab","requestTime":"15/Jun/2026:05:12:44 +0000","requestTimeEpoch":"1781500364402","resourcePath":"/NodeResource","responseLength":"67","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:45.368000+00:00 d781b274f7cf34608ca8c34b360d25b9 {"apiId":"zjiqu82rrc","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J4JGNzvHcEHCA=","httpMethod":"GET","integrationLatency":"23","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"33768996-d6ba-4b38-b731-2c79b7a0560d","requestTime":"15/Jun/2026:05:12:45 +0000","requestTimeEpoch":"1781500365368","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:46.233000+00:00 9c6f85570cbd561f6b75da2a3cee5695 {"apiId":"zjiqu82rrc","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"e_J4SHS7vHcEXrQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"14541bd5-1290-4887-a45e-c44b42faf243","requestTime":"15/Jun/2026:05:12:46 +0000","requestTimeEpoch":"1781500366233","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"7","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-15T05:12:47.201000+00:00 7a4d13814a2d1ba34ce39d2a23e12cfd {"apiId":"zjiqu82rrc","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"e_J4cEpBvHcEYtg=","httpMethod":"GET","integrationLatency":"12","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"8a2eda3d-3f06-4cad-b8e5-28144a2e5f29","requestTime":"15/Jun/2026:05:12:47 +0000","requestTimeEpoch":"1781500367201","resourcePath":"/NodeResource","responseLength":"80","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/be8dad0d-26d8-4767-982d-ff8ea02c51d2"}
2026-06-14 11:52:04          0 AWSLogs/015195098145/
2026-06-14 12:23:20       2558 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/14/19/15/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260614T1915Z_f3dc22d6.log.gz
2026-06-14 12:33:20       3181 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/14/19/25/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260614T1925Z_48043b91.log.gz
2026-06-14 19:38:23       2451 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/15/02/30/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260615T0230Z_090a944a.log.gz
2026-06-14 20:03:23       2449 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/15/03/00/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260615T0300Z_f16827d0.log.gz
2026-06-14 20:28:22       2482 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/15/03/20/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260615T0320Z_a0029db9.log.gz
2026-06-14 22:13:23       3191 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/06/15/05/10/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260615T0510Z_7b553a43.log.gz

## Script Exit Summary

- Checks run: 8
- Failures: 0
- Skipped: 0
- Result: PASS

Skipping WAF CloudWatch logs check because waf_log_group output is N/A.
Wrote summary document: /c/Users/John Sweeney/aws/lambda/lambda-skel/lambda-restapi-rbac-bedrock/Reports/rbac_test_report.md
RBAC_TEST_RESULT=PASS checks=8 failures=0 skipped=0
