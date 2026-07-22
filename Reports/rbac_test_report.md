# RBAC and WAF Test Report

- Generated (UTC): 2026-07-22T03:52:27Z
- Region: us-west-2
- Python API: https://4lltecsznk.execute-api.us-west-2.amazonaws.com/prod
- Node API: https://btix4heemh.execute-api.us-west-2.amazonaws.com/prod

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
Date: Wed, 22 Jul 2026 03:52:49 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: e7d6f732-4b2c-4de8-9f95-af7dc4c3b8a7
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: A4622ElxvHcEYvw=

{"message":"Unauthorized"}
HTTP/1.1 401 Unauthorized
Date: Wed, 22 Jul 2026 03:52:50 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: f617b005-3452-4833-ba4b-93ee70942acb
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: A463BGTlPHcEB8Q=

{"message":"Unauthorized"}
PASS: Python no-token auth (expected=401 actual=401)
PASS: Node no-token auth (expected=401 actual=401)
Positive auth test (valid token)
HTTP/1.1 200 OK
Date: Wed, 22 Jul 2026 03:52:51 GMT
Content-Type: application/json
Content-Length: 98
Connection: keep-alive
x-amzn-RequestId: c3b42dd2-0aae-4ef0-8993-ed2ba1034021
x-amz-apigw-id: A463GGgNPHcEaXQ=
X-Amzn-Trace-Id: Root=1-6a603e93-5e1604f6749a6ba34a61af5d;Parent=5b3265ac00ea70da;Sampled=0;Lineage=1:315d35d1:0

{"message": "Hello theo from Python!", "timestamp": "2026-07-22T03:52:51.629993", "role": "admin"}
HTTP/1.1 200 OK
Date: Wed, 22 Jul 2026 03:52:53 GMT
Content-Type: application/json
Content-Length: 67
Connection: keep-alive
x-amzn-RequestId: 0547626d-6f57-4e19-b03e-92289aea3627
x-amz-apigw-id: A463RGFevHcEhcA=
X-Amzn-Trace-Id: Root=1-6a603e94-62dd97240d272ff231aea6e2;Parent=1c3e8fdb584700e4;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
PASS: Python admin auth (expected=200 actual=200)
PASS: Node admin auth (expected=200 actual=200)
Scope/RBAC deny test with non-admin access token (expected: 403)
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:53 GMT
Content-Type: application/json
Content-Length: 50
Connection: keep-alive
x-amzn-RequestId: 02436b59-9c06-4a78-97e9-047c6ad6937f
x-amz-apigw-id: A463gG4avHcEDzg=
X-Amzn-Trace-Id: Root=1-6a603e95-0afe2f2a63d6223e503a521e;Parent=28605ffd640485ff;Sampled=0;Lineage=1:315d35d1:0

{"message": "Access denied: admin group required"}
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:54 GMT
Content-Type: application/json
Content-Length: 49
Connection: keep-alive
x-amzn-RequestId: 55bed6ed-c4fa-49d9-a4c7-e37f83db46e7
x-amz-apigw-id: A463kH1gvHcET7A=
X-Amzn-Trace-Id: Root=1-6a603e96-1defc872158ab9ab18eb1be4;Parent=33719346cee8a9f6;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"Access denied: admin group required"}
PASS: Python non-admin scope/RBAC deny (expected=403 actual=403)
PASS: Node non-admin scope/RBAC deny (expected=403 actual=403)
WAF strict XSS block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:54 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: eed63f63-e960-4d89-ade7-39a0bf8f6740
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: A463pHJGPHcEQGQ=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:55 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: a5d95a80-643c-42ac-9585-e726c371957b
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: A463vHZdPHcEluw=

{"message":"Forbidden"}
PASS: Python WAF strict XSS (expected=403 actual=403)
PASS: Node WAF strict XSS (expected=403 actual=403)
WAF strict SQLi block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:56 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 0aab3db5-194c-492f-8874-02e5ef7c26a6
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: A4631EAGvHcEiZQ=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Wed, 22 Jul 2026 03:52:56 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: b398d841-cd1b-4cf7-ab46-3e5f12ccf4e2
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: A4635HVOPHcEPFw=

{"message":"Forbidden"}
PASS: Python WAF SQLi (expected=403 actual=403)
PASS: Node WAF SQLi (expected=403 actual=403)
Strict WAF summary: XSS Python=403 Node=403; SQLi Python=403 Node=403; Result=PASS
## WAF Strict Block Result

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
        "CreationDateTime": "2026-07-21T17:32:28.645000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking",
        "TableId": "108afff4-287c-43c7-aa7f-6aca60ed8c28",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-21T17:32:28.645000-07:00"
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
        "CreationDateTime": "2026-07-21T17:32:32.079000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-revocation",
        "TableId": "8cb4ecac-839a-47e2-b477-200b72f43010",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-21T17:32:32.079000-07:00"
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
        "CreationDate": "2026-07-21T17:37:56.263000-07:00",
        "GroupName": "default",
        "LastModificationDate": "2026-07-21T19:16:54.765000-07:00",
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
    "CreationDate": "2026-07-21T17:37:56.263000-07:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-07-21T19:16:54.765000-07:00",
    "Name": "Invoke-unused-token-schedule",
    "ScheduleExpression": "rate(15 minutes)",
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
2026-07-22T03:52:30.669000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 INIT_START Runtime Version: python:3.9.v133	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:b46f7bc0f3da8071d1b824471f2c69c8766b756b827eb0455d2118c622ae7bcf
2026-07-22T03:52:31.121000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 START RequestId: 56bcaf91-379d-48e5-b755-2ac907ea5aee Version: $LATEST
2026-07-22T03:52:31.121000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 Incoming event: {}
2026-07-22T03:52:31.123000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 END RequestId: 56bcaf91-379d-48e5-b755-2ac907ea5aee
2026-07-22T03:52:31.123000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 REPORT RequestId: 56bcaf91-379d-48e5-b755-2ac907ea5aee	Duration: 1.40 ms	Billed Duration: 450 ms	Memory Size: 128 MB	Max Memory Used: 81 MB	Init Duration: 447.83 ms
2026-07-22T03:52:37.234000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 START RequestId: e2d98625-d4aa-4e94-9bf9-a5bbfc2d4a45 Version: $LATEST
2026-07-22T03:52:37.235000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 Incoming event: {}
2026-07-22T03:52:37.236000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 END RequestId: e2d98625-d4aa-4e94-9bf9-a5bbfc2d4a45
2026-07-22T03:52:37.236000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 REPORT RequestId: e2d98625-d4aa-4e94-9bf9-a5bbfc2d4a45	Duration: 1.26 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-22T03:52:51.629000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 START RequestId: 2785118f-d815-4bdf-958a-97fc3e002869 Version: $LATEST
2026-07-22T03:52:51.630000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4OGMxOTM2MC1iMDIxLTcwOTktMGQxNC1lNjM1YzA0N2JiMzkiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8zUGs4R253UFoiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiIxb3Bxcmc4OWRmMmdhbjNkZmk4Z2RrMWowMiIsIm9yaWdpbl9qdGkiOiJiOGZlNTU2Mi0zMTJmLTRiOTMtOWNhZC1lMDBhMTRjMjYxMjkiLCJldmVudF9pZCI6IjYzMjk1NjFhLWRjMTktNDJkZi05M2ZmLWViOTkzODVkY2ZhMCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ2OTE4NDQsImV4cCI6MTc4NDY5NTQ0NCwiaWF0IjoxNzg0NjkxODQ1LCJqdGkiOiIyNTcwYjA5Ni04MjViLTQ2NjctOGMwMy1jMTZkZTNkYjNmNDIiLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.cybElqnVukbztPBFjRyHyGZkwlFmulGGQKWAJed_tXZ60iv9uqqNFvFOGktRxQmTFO7ZmiyYO4Qi13s9Rwwhjg1HhJexQ8tABoSi1y5gAY9QboGTlErqND9pLFQXiTpq1KyqjImz8kxZ5S4Xak0kYG64kFXJ527d3WJi5CYrVbx3yrOVl8ZZjZKH1PCihhNreuGnwePfXtmAsL_Z-aIgQoJbLSbGNGddD6e_G9X_ZjWeL6wpmW2UH9_yOfhU7qVgT1lTuZQ1tUMak6og-eUAbS0GUnppCASDzMs8AwFqA8VizT_830VodZt7P9XonjEo_qFlGGN6KvLrMVnnEYZthQ", "Host": "4lltecsznk.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a603e93-5e1604f6749a6ba34a61af5d", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4OGMxOTM2MC1iMDIxLTcwOTktMGQxNC1lNjM1YzA0N2JiMzkiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8zUGs4R253UFoiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiIxb3Bxcmc4OWRmMmdhbjNkZmk4Z2RrMWowMiIsIm9yaWdpbl9qdGkiOiJiOGZlNTU2Mi0zMTJmLTRiOTMtOWNhZC1lMDBhMTRjMjYxMjkiLCJldmVudF9pZCI6IjYzMjk1NjFhLWRjMTktNDJkZi05M2ZmLWViOTkzODVkY2ZhMCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ2OTE4NDQsImV4cCI6MTc4NDY5NTQ0NCwiaWF0IjoxNzg0NjkxODQ1LCJqdGkiOiIyNTcwYjA5Ni04MjViLTQ2NjctOGMwMy1jMTZkZTNkYjNmNDIiLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.cybElqnVukbztPBFjRyHyGZkwlFmulGGQKWAJed_tXZ60iv9uqqNFvFOGktRxQmTFO7ZmiyYO4Qi13s9Rwwhjg1HhJexQ8tABoSi1y5gAY9QboGTlErqND9pLFQXiTpq1KyqjImz8kxZ5S4Xak0kYG64kFXJ527d3WJi5CYrVbx3yrOVl8ZZjZKH1PCihhNreuGnwePfXtmAsL_Z-aIgQoJbLSbGNGddD6e_G9X_ZjWeL6wpmW2UH9_yOfhU7qVgT1lTuZQ1tUMak6og-eUAbS0GUnppCASDzMs8AwFqA8VizT_830VodZt7P9XonjEo_qFlGGN6KvLrMVnnEYZthQ"], "Host": ["4lltecsznk.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a603e93-5e1604f6749a6ba34a61af5d"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "theo"}, "multiValueQueryStringParameters": {"name": ["theo"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "0n77qf", "authorizer": {"claims": {"sub": "88c19360-b021-7099-0d14-e635c047bb39", "cognito:groups": "admin", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_3Pk8GnwPZ", "version": "2", "client_id": "1opqrg89df2gan3dfi8gdk1j02", "origin_jti": "b8fe5562-312f-4b93-9cad-e00a14c26129", "event_id": "6329561a-dc19-42df-93ff-eb99385dcfa0", "token_use": "access", "scope": "rbac-api/admin openid rbac-api/user", "auth_time": "1784691844", "exp": "Wed Jul 22 04:44:04 UTC 2026", "iat": "Wed Jul 22 03:44:05 UTC 2026", "jti": "2570b096-825b-4667-8c03-c16de3db3f42", "username": "admin.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "A463GGgNPHcEaXQ=", "requestTime": "22/Jul/2026:03:52:51 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "4lltecsznk", "requestTimeEpoch": 1784692371355, "requestId": "c3b42dd2-0aae-4ef0-8993-ed2ba1034021", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "4lltecsznk.execute-api.us-west-2.amazonaws.com", "deploymentId": "pn4tns", "apiId": "4lltecsznk"}, "body": null, "isBase64Encoded": false}
2026-07-22T03:52:51.969000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 Response: {"message": "Hello theo from Python!", "timestamp": "2026-07-22T03:52:51.629993", "role": "admin"}
2026-07-22T03:52:51.989000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 END RequestId: 2785118f-d815-4bdf-958a-97fc3e002869
2026-07-22T03:52:51.989000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 REPORT RequestId: 2785118f-d815-4bdf-958a-97fc3e002869	Duration: 359.79 ms	Billed Duration: 360 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-22T03:52:53.959000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 START RequestId: d427bf37-030a-438f-a0e4-514b517d50c3 Version: $LATEST
2026-07-22T03:52:53.959000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyOGUxNDM1MC0xMGUxLTcwYzEtOTA0Ni01MTRmYjA5Y2I4ZDgiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzNQazhHbndQWiIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjFvcHFyZzg5ZGYyZ2FuM2RmaThnZGsxajAyIiwib3JpZ2luX2p0aSI6IjNkMWNhODAxLTRmZTktNDFhZS1iYWY1LTJiZTgxZTA2ZjllZSIsImV2ZW50X2lkIjoiOTI0N2JjNmQtNGQxNC00YzAzLThiNjMtZGUxOTgzZGUyNzQwIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDY5MjEzNCwiZXhwIjoxNzg0Njk1NzM0LCJpYXQiOjE3ODQ2OTIxMzQsImp0aSI6IjFjYTcwZGZhLWNiOTctNDUzMS1iOWM2LWVmOTg0ZmYxZjdmZCIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.ZRnpY-IQBPJ6VdCuukwn3cjPxNmibXt87sv-gc3cKoa6z-ABMozZk6BDJitgD1IujEUSIuX3cwe6W8rFqH0DV93EgzGOzqIc7gcqfaZRC9Lb2dBS1ICadmxHInOSZyGIGYiQ8iN0e6nEqUdRYgaiid9DVEJ3Uwmi3eQv-J3u5C7oH7agOSUKAKRRmnunLwjzQRBcunRj4bwR4kK4Gxy4x1kDdEmnfr7XbMxUJm8NINZq3Cf7qRgqqgWi_wd6cMwBzqcYVxDARsZwvuDsdx-xkHR5rtj00OsuLQM1kLW2_fRkrlbEpczzvsdNvME1BbfjSPtvCZKMxAeb_g1TjjfI9g", "Host": "4lltecsznk.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.10.1", "X-Amzn-Trace-Id": "Root=1-6a603e95-0afe2f2a63d6223e503a521e", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyOGUxNDM1MC0xMGUxLTcwYzEtOTA0Ni01MTRmYjA5Y2I4ZDgiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzNQazhHbndQWiIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjFvcHFyZzg5ZGYyZ2FuM2RmaThnZGsxajAyIiwib3JpZ2luX2p0aSI6IjNkMWNhODAxLTRmZTktNDFhZS1iYWY1LTJiZTgxZTA2ZjllZSIsImV2ZW50X2lkIjoiOTI0N2JjNmQtNGQxNC00YzAzLThiNjMtZGUxOTgzZGUyNzQwIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDY5MjEzNCwiZXhwIjoxNzg0Njk1NzM0LCJpYXQiOjE3ODQ2OTIxMzQsImp0aSI6IjFjYTcwZGZhLWNiOTctNDUzMS1iOWM2LWVmOTg0ZmYxZjdmZCIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.ZRnpY-IQBPJ6VdCuukwn3cjPxNmibXt87sv-gc3cKoa6z-ABMozZk6BDJitgD1IujEUSIuX3cwe6W8rFqH0DV93EgzGOzqIc7gcqfaZRC9Lb2dBS1ICadmxHInOSZyGIGYiQ8iN0e6nEqUdRYgaiid9DVEJ3Uwmi3eQv-J3u5C7oH7agOSUKAKRRmnunLwjzQRBcunRj4bwR4kK4Gxy4x1kDdEmnfr7XbMxUJm8NINZq3Cf7qRgqqgWi_wd6cMwBzqcYVxDARsZwvuDsdx-xkHR5rtj00OsuLQM1kLW2_fRkrlbEpczzvsdNvME1BbfjSPtvCZKMxAeb_g1TjjfI9g"], "Host": ["4lltecsznk.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.10.1"], "X-Amzn-Trace-Id": ["Root=1-6a603e95-0afe2f2a63d6223e503a521e"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "0n77qf", "authorizer": {"claims": {"sub": "28e14350-10e1-70c1-9046-514fb09cb8d8", "cognito:groups": "user", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_3Pk8GnwPZ", "version": "2", "client_id": "1opqrg89df2gan3dfi8gdk1j02", "origin_jti": "3d1ca801-4fe9-41ae-baf5-2be81e06f9ee", "event_id": "9247bc6d-4d14-4c03-8b63-de1983de2740", "token_use": "access", "scope": "openid rbac-api/user", "auth_time": "1784692134", "exp": "Wed Jul 22 04:48:54 UTC 2026", "iat": "Wed Jul 22 03:48:54 UTC 2026", "jti": "1ca70dfa-cb97-4531-b9c6-ef984ff1f7fd", "username": "user.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "A463gG4avHcEDzg=", "requestTime": "22/Jul/2026:03:52:53 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "4lltecsznk", "requestTimeEpoch": 1784692373914, "requestId": "02436b59-9c06-4a78-97e9-047c6ad6937f", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.10.1", "user": null}, "domainName": "4lltecsznk.execute-api.us-west-2.amazonaws.com", "deploymentId": "pn4tns", "apiId": "4lltecsznk"}, "body": null, "isBase64Encoded": false}
2026-07-22T03:52:53.960000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 END RequestId: d427bf37-030a-438f-a0e4-514b517d50c3
2026-07-22T03:52:53.960000+00:00 2026/07/22/[$LATEST]8e6debb3ccb74abaa38c0e626efbcdd3 REPORT RequestId: d427bf37-030a-438f-a0e4-514b517d50c3	Duration: 1.20 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 81 MB
2026-07-22T03:52:34.157000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee INIT_START Runtime Version: nodejs:24.v48	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:adfa9c68b2b34ae1cba34f70c4369649bca17aea5fe29e10414b040bf256e6c6
2026-07-22T03:52:34.460000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee START RequestId: c7bb77a1-774b-42a2-a86a-a8390d6215cd Version: $LATEST
2026-07-22T03:52:34.461000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee 2026-07-22T03:52:34.461Z	c7bb77a1-774b-42a2-a86a-a8390d6215cd	INFO	Incoming event: {}
2026-07-22T03:52:34.493000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee END RequestId: c7bb77a1-774b-42a2-a86a-a8390d6215cd
2026-07-22T03:52:34.493000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee REPORT RequestId: c7bb77a1-774b-42a2-a86a-a8390d6215cd	Duration: 32.56 ms	Billed Duration: 332 ms	Memory Size: 128 MB	Max Memory Used: 98 MB	Init Duration: 299.31 ms
2026-07-22T03:52:52.537000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee START RequestId: 26ec3b95-4fbc-4d2b-904e-2a8d7df72331 Version: $LATEST
2026-07-22T03:52:52.538000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee 2026-07-22T03:52:52.538Z	26ec3b95-4fbc-4d2b-904e-2a8d7df72331	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4OGMxOTM2MC1iMDIxLTcwOTktMGQxNC1lNjM1YzA0N2JiMzkiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8zUGs4R253UFoiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiIxb3Bxcmc4OWRmMmdhbjNkZmk4Z2RrMWowMiIsIm9yaWdpbl9qdGkiOiJiOGZlNTU2Mi0zMTJmLTRiOTMtOWNhZC1lMDBhMTRjMjYxMjkiLCJldmVudF9pZCI6IjYzMjk1NjFhLWRjMTktNDJkZi05M2ZmLWViOTkzODVkY2ZhMCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ2OTE4NDQsImV4cCI6MTc4NDY5NTQ0NCwiaWF0IjoxNzg0NjkxODQ1LCJqdGkiOiIyNTcwYjA5Ni04MjViLTQ2NjctOGMwMy1jMTZkZTNkYjNmNDIiLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.cybElqnVukbztPBFjRyHyGZkwlFmulGGQKWAJed_tXZ60iv9uqqNFvFOGktRxQmTFO7ZmiyYO4Qi13s9Rwwhjg1HhJexQ8tABoSi1y5gAY9QboGTlErqND9pLFQXiTpq1KyqjImz8kxZ5S4Xak0kYG64kFXJ527d3WJi5CYrVbx3yrOVl8ZZjZKH1PCihhNreuGnwePfXtmAsL_Z-aIgQoJbLSbGNGddD6e_G9X_ZjWeL6wpmW2UH9_yOfhU7qVgT1lTuZQ1tUMak6og-eUAbS0GUnppCASDzMs8AwFqA8VizT_830VodZt7P9XonjEo_qFlGGN6KvLrMVnnEYZthQ","Host":"btix4heemh.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a603e94-62dd97240d272ff231aea6e2","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4OGMxOTM2MC1iMDIxLTcwOTktMGQxNC1lNjM1YzA0N2JiMzkiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8zUGs4R253UFoiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiIxb3Bxcmc4OWRmMmdhbjNkZmk4Z2RrMWowMiIsIm9yaWdpbl9qdGkiOiJiOGZlNTU2Mi0zMTJmLTRiOTMtOWNhZC1lMDBhMTRjMjYxMjkiLCJldmVudF9pZCI6IjYzMjk1NjFhLWRjMTktNDJkZi05M2ZmLWViOTkzODVkY2ZhMCIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicmJhYy1hcGkvYWRtaW4gb3BlbmlkIHJiYWMtYXBpL3VzZXIiLCJhdXRoX3RpbWUiOjE3ODQ2OTE4NDQsImV4cCI6MTc4NDY5NTQ0NCwiaWF0IjoxNzg0NjkxODQ1LCJqdGkiOiIyNTcwYjA5Ni04MjViLTQ2NjctOGMwMy1jMTZkZTNkYjNmNDIiLCJ1c2VybmFtZSI6ImFkbWluLnRlc3QifQ.cybElqnVukbztPBFjRyHyGZkwlFmulGGQKWAJed_tXZ60iv9uqqNFvFOGktRxQmTFO7ZmiyYO4Qi13s9Rwwhjg1HhJexQ8tABoSi1y5gAY9QboGTlErqND9pLFQXiTpq1KyqjImz8kxZ5S4Xak0kYG64kFXJ527d3WJi5CYrVbx3yrOVl8ZZjZKH1PCihhNreuGnwePfXtmAsL_Z-aIgQoJbLSbGNGddD6e_G9X_ZjWeL6wpmW2UH9_yOfhU7qVgT1lTuZQ1tUMak6og-eUAbS0GUnppCASDzMs8AwFqA8VizT_830VodZt7P9XonjEo_qFlGGN6KvLrMVnnEYZthQ"],"Host":["btix4heemh.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a603e94-62dd97240d272ff231aea6e2"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"theo"},"multiValueQueryStringParameters":{"name":["theo"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"nfuwwd","authorizer":{"claims":{"sub":"88c19360-b021-7099-0d14-e635c047bb39","cognito:groups":"admin","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_3Pk8GnwPZ","version":"2","client_id":"1opqrg89df2gan3dfi8gdk1j02","origin_jti":"b8fe5562-312f-4b93-9cad-e00a14c26129","event_id":"6329561a-dc19-42df-93ff-eb99385dcfa0","token_use":"access","scope":"rbac-api/admin openid rbac-api/user","auth_time":"1784691844","exp":"Wed Jul 22 04:44:04 UTC 2026","iat":"Wed Jul 22 03:44:05 UTC 2026","jti":"2570b096-825b-4667-8c03-c16de3db3f42","username":"admin.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"A463RGFevHcEhcA=","requestTime":"22/Jul/2026:03:52:52 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"btix4heemh","requestTimeEpoch":1784692372486,"requestId":"0547626d-6f57-4e19-b03e-92289aea3627","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"btix4heemh.execute-api.us-west-2.amazonaws.com","deploymentId":"2pi5mk","apiId":"btix4heemh"},"body":null,"isBase64Encoded":false}
2026-07-22T03:52:53.433000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee 2026-07-22T03:52:53.433Z	26ec3b95-4fbc-4d2b-904e-2a8d7df72331	INFO	Response: {"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
2026-07-22T03:52:53.453000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee END RequestId: 26ec3b95-4fbc-4d2b-904e-2a8d7df72331
2026-07-22T03:52:53.453000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee REPORT RequestId: 26ec3b95-4fbc-4d2b-904e-2a8d7df72331	Duration: 915.09 ms	Billed Duration: 916 ms	Memory Size: 128 MB	Max Memory Used: 98 MB
2026-07-22T03:52:54.385000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee START RequestId: 360ec78e-e57c-42a4-93a8-e6f944556494 Version: $LATEST
2026-07-22T03:52:54.386000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee 2026-07-22T03:52:54.386Z	360ec78e-e57c-42a4-93a8-e6f944556494	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyOGUxNDM1MC0xMGUxLTcwYzEtOTA0Ni01MTRmYjA5Y2I4ZDgiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzNQazhHbndQWiIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjFvcHFyZzg5ZGYyZ2FuM2RmaThnZGsxajAyIiwib3JpZ2luX2p0aSI6IjNkMWNhODAxLTRmZTktNDFhZS1iYWY1LTJiZTgxZTA2ZjllZSIsImV2ZW50X2lkIjoiOTI0N2JjNmQtNGQxNC00YzAzLThiNjMtZGUxOTgzZGUyNzQwIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDY5MjEzNCwiZXhwIjoxNzg0Njk1NzM0LCJpYXQiOjE3ODQ2OTIxMzQsImp0aSI6IjFjYTcwZGZhLWNiOTctNDUzMS1iOWM2LWVmOTg0ZmYxZjdmZCIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.ZRnpY-IQBPJ6VdCuukwn3cjPxNmibXt87sv-gc3cKoa6z-ABMozZk6BDJitgD1IujEUSIuX3cwe6W8rFqH0DV93EgzGOzqIc7gcqfaZRC9Lb2dBS1ICadmxHInOSZyGIGYiQ8iN0e6nEqUdRYgaiid9DVEJ3Uwmi3eQv-J3u5C7oH7agOSUKAKRRmnunLwjzQRBcunRj4bwR4kK4Gxy4x1kDdEmnfr7XbMxUJm8NINZq3Cf7qRgqqgWi_wd6cMwBzqcYVxDARsZwvuDsdx-xkHR5rtj00OsuLQM1kLW2_fRkrlbEpczzvsdNvME1BbfjSPtvCZKMxAeb_g1TjjfI9g","Host":"btix4heemh.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.10.1","X-Amzn-Trace-Id":"Root=1-6a603e96-1defc872158ab9ab18eb1be4","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJ5SjFZa1RxWnJ3bWllSE4zc2VHRVU1UlEvZmhjWHFDRkl1MVM2KzQxVnl3PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIyOGUxNDM1MC0xMGUxLTcwYzEtOTA0Ni01MTRmYjA5Y2I4ZDgiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzNQazhHbndQWiIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6IjFvcHFyZzg5ZGYyZ2FuM2RmaThnZGsxajAyIiwib3JpZ2luX2p0aSI6IjNkMWNhODAxLTRmZTktNDFhZS1iYWY1LTJiZTgxZTA2ZjllZSIsImV2ZW50X2lkIjoiOTI0N2JjNmQtNGQxNC00YzAzLThiNjMtZGUxOTgzZGUyNzQwIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4NDY5MjEzNCwiZXhwIjoxNzg0Njk1NzM0LCJpYXQiOjE3ODQ2OTIxMzQsImp0aSI6IjFjYTcwZGZhLWNiOTctNDUzMS1iOWM2LWVmOTg0ZmYxZjdmZCIsInVzZXJuYW1lIjoidXNlci50ZXN0In0.ZRnpY-IQBPJ6VdCuukwn3cjPxNmibXt87sv-gc3cKoa6z-ABMozZk6BDJitgD1IujEUSIuX3cwe6W8rFqH0DV93EgzGOzqIc7gcqfaZRC9Lb2dBS1ICadmxHInOSZyGIGYiQ8iN0e6nEqUdRYgaiid9DVEJ3Uwmi3eQv-J3u5C7oH7agOSUKAKRRmnunLwjzQRBcunRj4bwR4kK4Gxy4x1kDdEmnfr7XbMxUJm8NINZq3Cf7qRgqqgWi_wd6cMwBzqcYVxDARsZwvuDsdx-xkHR5rtj00OsuLQM1kLW2_fRkrlbEpczzvsdNvME1BbfjSPtvCZKMxAeb_g1TjjfI9g"],"Host":["btix4heemh.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.10.1"],"X-Amzn-Trace-Id":["Root=1-6a603e96-1defc872158ab9ab18eb1be4"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"nfuwwd","authorizer":{"claims":{"sub":"28e14350-10e1-70c1-9046-514fb09cb8d8","cognito:groups":"user","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_3Pk8GnwPZ","version":"2","client_id":"1opqrg89df2gan3dfi8gdk1j02","origin_jti":"3d1ca801-4fe9-41ae-baf5-2be81e06f9ee","event_id":"9247bc6d-4d14-4c03-8b63-de1983de2740","token_use":"access","scope":"openid rbac-api/user","auth_time":"1784692134","exp":"Wed Jul 22 04:48:54 UTC 2026","iat":"Wed Jul 22 03:48:54 UTC 2026","jti":"1ca70dfa-cb97-4531-b9c6-ef984ff1f7fd","username":"user.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"A463kH1gvHcET7A=","requestTime":"22/Jul/2026:03:52:54 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"btix4heemh","requestTimeEpoch":1784692374330,"requestId":"55bed6ed-c4fa-49d9-a4c7-e37f83db46e7","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.10.1","user":null},"domainName":"btix4heemh.execute-api.us-west-2.amazonaws.com","deploymentId":"2pi5mk","apiId":"btix4heemh"},"body":null,"isBase64Encoded":false}
2026-07-22T03:52:54.391000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee END RequestId: 360ec78e-e57c-42a4-93a8-e6f944556494
2026-07-22T03:52:54.391000+00:00 2026/07/22/[$LATEST]4d9204ca996c4d9bb21818e050ff8fee REPORT RequestId: 360ec78e-e57c-42a4-93a8-e6f944556494	Duration: 1.90 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 98 MB
Checking API Gateway access logs...
2026-07-22T03:52:49.745000+00:00 6e654907fa42d448c909e3b61e8b6b45 {"apiId":"4lltecsznk","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"A4622ElxvHcEYvw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"e7d6f732-4b2c-4de8-9f95-af7dc4c3b8a7","requestTime":"22/Jul/2026:03:52:49 +0000","requestTimeEpoch":"1784692369745","resourcePath":"/PythonResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:51.355000+00:00 000da73a1ad94452c2cef6acde2d5896 {"apiId":"4lltecsznk","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"A463GGgNPHcEaXQ=","httpMethod":"GET","integrationLatency":"351","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"c3b42dd2-0aae-4ef0-8993-ed2ba1034021","requestTime":"22/Jul/2026:03:52:51 +0000","requestTimeEpoch":"1784692371355","resourcePath":"/PythonResource","responseLength":"98","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:53.914000+00:00 fb2493945cf7a5511c42ad254614b7fe {"apiId":"4lltecsznk","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"A463gG4avHcEDzg=","httpMethod":"GET","integrationLatency":"12","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"02436b59-9c06-4a78-97e9-047c6ad6937f","requestTime":"22/Jul/2026:03:52:53 +0000","requestTimeEpoch":"1784692373914","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:54.821000+00:00 891a9806c75fe6bfb98283b857441f2f {"apiId":"4lltecsznk","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"A463pHJGPHcEQGQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"eed63f63-e960-4d89-ade7-39a0bf8f6740","requestTime":"22/Jul/2026:03:52:54 +0000","requestTimeEpoch":"1784692374821","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:56.001000+00:00 fc78687806c584d3d738b95d17fb1a1f {"apiId":"4lltecsznk","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"A4631EAGvHcEiZQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"0aab3db5-194c-492f-8874-02e5ef7c26a6","requestTime":"22/Jul/2026:03:52:56 +0000","requestTimeEpoch":"1784692376001","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:50.839000+00:00 8f9b98d1a21121d74b2193b616f1b9ce {"apiId":"btix4heemh","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"A463BGTlPHcEB8Q=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"f617b005-3452-4833-ba4b-93ee70942acb","requestTime":"22/Jul/2026:03:52:50 +0000","requestTimeEpoch":"1784692370839","resourcePath":"/NodeResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:52.486000+00:00 1bfa255363aec6356d073d3afa246e70 {"apiId":"btix4heemh","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"A463RGFevHcEhcA=","httpMethod":"GET","integrationLatency":"925","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"0547626d-6f57-4e19-b03e-92289aea3627","requestTime":"22/Jul/2026:03:52:52 +0000","requestTimeEpoch":"1784692372486","resourcePath":"/NodeResource","responseLength":"67","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:54.330000+00:00 410ee9cae1038b01c30056aa6294b912 {"apiId":"btix4heemh","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"A463kH1gvHcET7A=","httpMethod":"GET","integrationLatency":"20","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"55bed6ed-c4fa-49d9-a4c7-e37f83db46e7","requestTime":"22/Jul/2026:03:52:54 +0000","requestTimeEpoch":"1784692374330","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:55.469000+00:00 ca3d0fda0964f4f949017aef4ce1cbf1 {"apiId":"btix4heemh","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"A463vHZdPHcEluw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"a5d95a80-643c-42ac-9585-e726c371957b","requestTime":"22/Jul/2026:03:52:55 +0000","requestTimeEpoch":"1784692375469","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-22T03:52:56.407000+00:00 869230d6fb6803286ddab5ba118c333c {"apiId":"btix4heemh","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"A4635HVOPHcEPFw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"b398d841-cd1b-4cf7-ab46-3e5f12ccf4e2","requestTime":"22/Jul/2026:03:52:56 +0000","requestTimeEpoch":"1784692376407","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.10.1","wafLatency":"5","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/093db73c-178f-4525-9411-0fac714569ef"}
2026-07-21 17:32:53          0 AWSLogs/015195098145/

## Script Exit Summary

- Checks run: 10
- Failures: 0
- Skipped: 0
- Result: PASS

Skipping WAF CloudWatch logs check because waf_log_group output is N/A.
Wrote summary document: /c/Users/John Sweeney/aws/lambda/SEIR-Serverless-SOAR/Reports/rbac_test_report.md
RBAC_TEST_RESULT=PASS checks=10 failures=0 skipped=0
