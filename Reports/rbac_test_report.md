# RBAC and WAF Test Report

- Generated (UTC): 2026-07-02T11:54:17Z
- Region: us-west-2
- Python API: https://o5p491t2v9.execute-api.us-west-2.amazonaws.com/prod
- Node API: https://nhjz4yjbdg.execute-api.us-west-2.amazonaws.com/prod

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
Date: Thu, 02 Jul 2026 11:54:44 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: 60838619-695e-45bc-8d3d-331626f88932
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: f4GssEp9vHcEbdQ=

{"message":"Unauthorized"}
HTTP/1.1 401 Unauthorized
Date: Thu, 02 Jul 2026 11:54:44 GMT
Content-Type: application/json
Content-Length: 26
Connection: keep-alive
x-amzn-RequestId: 112162de-a0dd-4494-9c96-05fea99597b9
x-amzn-ErrorType: UnauthorizedException
x-amz-apigw-id: f4GszGiePHcEA8A=

{"message":"Unauthorized"}
PASS: Python no-token auth (expected=401 actual=401)
PASS: Node no-token auth (expected=401 actual=401)
Positive auth test (valid token)
HTTP/1.1 200 OK
Date: Thu, 02 Jul 2026 11:54:45 GMT
Content-Type: application/json
Content-Length: 98
Connection: keep-alive
x-amzn-RequestId: a0a307b3-ba01-458d-ae55-7471d721105d
x-amz-apigw-id: f4Gs3HbOvHcEbCQ=
X-Amzn-Trace-Id: Root=1-6a465185-3266443d72b842c726a55d9d;Parent=21709c8941b350f8;Sampled=0;Lineage=1:315d35d1:0

{"message": "Hello theo from Python!", "timestamp": "2026-07-02T11:54:45.416764", "role": "admin"}
HTTP/1.1 200 OK
Date: Thu, 02 Jul 2026 11:54:47 GMT
Content-Type: application/json
Content-Length: 67
Connection: keep-alive
x-amzn-RequestId: fdbbb863-8b79-4d26-8c42-acd88e913efc
x-amz-apigw-id: f4GtCEH0vHcEa-Q=
X-Amzn-Trace-Id: Root=1-6a465186-1db843e353b5592e1d15bdd1;Parent=5d286b459403f8d9;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
PASS: Python admin auth (expected=200 actual=200)
PASS: Node admin auth (expected=200 actual=200)
Scope/RBAC deny test with non-admin access token (expected: 403)
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:47 GMT
Content-Type: application/json
Content-Length: 50
Connection: keep-alive
x-amzn-RequestId: 5d0eeaae-670e-4739-b775-34388df8e359
x-amz-apigw-id: f4GtPFB4vHcEMZg=
X-Amzn-Trace-Id: Root=1-6a465187-2222bd27467116ba452ad0f2;Parent=23791a4671dca539;Sampled=0;Lineage=1:315d35d1:0

{"message": "Access denied: admin group required"}
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:48 GMT
Content-Type: application/json
Content-Length: 49
Connection: keep-alive
x-amzn-RequestId: 18c8be9e-b670-4f0d-a718-18e67ab680cd
x-amz-apigw-id: f4GtVH-XvHcEi3A=
X-Amzn-Trace-Id: Root=1-6a465188-2b9acb91594adc3a2a2d92de;Parent=26bd6e9f4f800dc7;Sampled=0;Lineage=1:9f5d4f71:0

{"message":"Access denied: admin group required"}
PASS: Python non-admin scope/RBAC deny (expected=403 actual=403)
PASS: Node non-admin scope/RBAC deny (expected=403 actual=403)
WAF strict XSS block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:48 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 0afb41b6-60d7-4a56-bf47-acf1fbcabec4
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: f4GtaFqHvHcEMuw=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:49 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 14a47872-41f4-4a6f-8c04-a7b2e94bba72
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: f4GteGrHPHcEVJg=

{"message":"Forbidden"}
PASS: Python WAF strict XSS (expected=403 actual=403)
PASS: Node WAF strict XSS (expected=403 actual=403)
WAF strict SQLi block test - expected: 403 / WAF_BLOCK
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:49 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: aa2c15f9-8ed3-4018-a300-c25c08f0ba24
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: f4GtjEsGvHcERwQ=

{"message":"Forbidden"}
HTTP/1.1 403 Forbidden
Date: Thu, 02 Jul 2026 11:54:50 GMT
Content-Type: application/json
Content-Length: 23
Connection: keep-alive
x-amzn-RequestId: 13c7581e-b09b-4c8e-a184-b344cbf9883b
x-amzn-ErrorType: ForbiddenException
x-amz-apigw-id: f4GtoHpwvHcEU3Q=

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
        "CreationDateTime": "2026-07-02T02:32:41.861000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-tracking",
        "TableId": "3ed790bc-0d29-4bf9-ae27-fa2ecbcf859d",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-02T02:32:41.861000-07:00"
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
Checking tracked non-admin token state after deny-path tests...
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
        "CreationDateTime": "2026-07-02T02:32:41.143000-07:00",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-west-2:015195098145:table/token-revocation",
        "TableId": "fd8f4a93-b9b5-42aa-91e9-489f1f07d6a3",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": "2026-07-02T02:32:41.143000-07:00"
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
        "CreationDate": "2026-07-02T02:34:09.397000-07:00",
        "GroupName": "default",
        "LastModificationDate": "2026-07-02T02:34:09.397000-07:00",
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
    "CreationDate": "2026-07-02T02:34:09.397000-07:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-07-02T02:34:09.397000-07:00",
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
2026-07-02T11:43:52.850000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 INIT_START Runtime Version: python:3.9.v133	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:b46f7bc0f3da8071d1b824471f2c69c8766b756b827eb0455d2118c622ae7bcf
2026-07-02T11:43:53.326000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 START RequestId: a97bf47c-0a22-4237-8e36-50ed8065a887 Version: $LATEST
2026-07-02T11:43:53.327000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw", "Host": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.13.0", "X-Amzn-Trace-Id": "Root=1-6a464ef8-6ae629315d45f81e58ee5a15", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw"], "Host": ["o5p491t2v9.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.13.0"], "X-Amzn-Trace-Id": ["Root=1-6a464ef8-6ae629315d45f81e58ee5a15"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "eazplx", "authorizer": {"claims": {"sub": "b80153d0-40f1-707b-4f10-0ab5a5e93e60", "cognito:groups": "user", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91", "version": "2", "client_id": "s148ajh0lhaib4qp3lpfcja5v", "origin_jti": "9d5ae5c2-e64b-4f56-b9ac-32c78642fe2d", "event_id": "95a89b7d-1327-4159-8556-128ce1361fa7", "token_use": "access", "scope": "openid rbac-api/user", "auth_time": "1782992567", "exp": "Thu Jul 02 12:42:47 UTC 2026", "iat": "Thu Jul 02 11:42:47 UTC 2026", "jti": "a9918bf6-5d52-4339-81da-ea73d687c1cc", "username": "user.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "f4FG6GoQvHcEtuQ=", "requestTime": "02/Jul/2026:11:43:52 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "o5p491t2v9", "requestTimeEpoch": 1782992632627, "requestId": "1be02043-9fd1-43a9-ace6-f4c6e4ec2603", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.13.0", "user": null}, "domainName": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "deploymentId": "p4kh99", "apiId": "o5p491t2v9"}, "body": null, "isBase64Encoded": false}
2026-07-02T11:43:53.328000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 END RequestId: a97bf47c-0a22-4237-8e36-50ed8065a887
2026-07-02T11:43:53.328000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 REPORT RequestId: a97bf47c-0a22-4237-8e36-50ed8065a887	Duration: 1.71 ms	Billed Duration: 475 ms	Memory Size: 128 MB	Max Memory Used: 80 MB	Init Duration: 472.44 ms
2026-07-02T11:43:55.678000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 START RequestId: ac238927-4828-459f-93b2-7c45c32aaf87 Version: $LATEST
2026-07-02T11:43:55.678000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA", "Host": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.13.0", "X-Amzn-Trace-Id": "Root=1-6a464efb-6dc6692937e5a50c0bcfb83b", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA"], "Host": ["o5p491t2v9.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.13.0"], "X-Amzn-Trace-Id": ["Root=1-6a464efb-6dc6692937e5a50c0bcfb83b"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "Norrin"}, "multiValueQueryStringParameters": {"name": ["Norrin"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "eazplx", "authorizer": {"claims": {"sub": "58e11340-10d1-701e-4cdc-41e9b488367d", "cognito:groups": "admin", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91", "version": "2", "client_id": "s148ajh0lhaib4qp3lpfcja5v", "origin_jti": "c7113241-24e8-4fee-a7b1-aaf2eb91a355", "event_id": "a3698286-776a-41fb-9cdc-8350c5e0110a", "token_use": "access", "scope": "rbac-api/admin openid rbac-api/user", "auth_time": "1782992389", "exp": "Thu Jul 02 12:39:49 UTC 2026", "iat": "Thu Jul 02 11:39:49 UTC 2026", "jti": "fd4e3e69-a231-49ba-8aa5-a5755086cda2", "username": "admin.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "f4FHYGbaPHcElMw=", "requestTime": "02/Jul/2026:11:43:55 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "o5p491t2v9", "requestTimeEpoch": 1782992635624, "requestId": "92ba0ad0-5358-4ace-b64f-015c4626a9c5", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.13.0", "user": null}, "domainName": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "deploymentId": "p4kh99", "apiId": "o5p491t2v9"}, "body": null, "isBase64Encoded": false}
2026-07-02T11:43:56.018000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 Response: {"message": "Hello Norrin from Python!", "timestamp": "2026-07-02T11:43:55.678635", "role": "admin"}
2026-07-02T11:43:56.038000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 END RequestId: ac238927-4828-459f-93b2-7c45c32aaf87
2026-07-02T11:43:56.038000+00:00 2026/07/02/[$LATEST]560b56a7e1ba4d908fd3f0ed1e53bdb2 REPORT RequestId: ac238927-4828-459f-93b2-7c45c32aaf87	Duration: 359.78 ms	Billed Duration: 360 ms	Memory Size: 128 MB	Max Memory Used: 82 MB
2026-07-02T11:54:18.310000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 INIT_START Runtime Version: python:3.9.v133	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:b46f7bc0f3da8071d1b824471f2c69c8766b756b827eb0455d2118c622ae7bcf
2026-07-02T11:54:18.771000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 START RequestId: dbccde9f-475a-4583-870f-4304b0ffe18f Version: $LATEST
2026-07-02T11:54:18.771000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 Incoming event: {}
2026-07-02T11:54:18.773000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 END RequestId: dbccde9f-475a-4583-870f-4304b0ffe18f
2026-07-02T11:54:18.773000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 REPORT RequestId: dbccde9f-475a-4583-870f-4304b0ffe18f	Duration: 1.56 ms	Billed Duration: 459 ms	Memory Size: 128 MB	Max Memory Used: 80 MB	Init Duration: 456.89 ms
2026-07-02T11:54:32.011000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 START RequestId: 3a5ac190-a1b7-4a09-901c-4d2d9191c8f9 Version: $LATEST
2026-07-02T11:54:32.012000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 Incoming event: {}
2026-07-02T11:54:32.013000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 END RequestId: 3a5ac190-a1b7-4a09-901c-4d2d9191c8f9
2026-07-02T11:54:32.013000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 REPORT RequestId: 3a5ac190-a1b7-4a09-901c-4d2d9191c8f9	Duration: 1.15 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 80 MB
2026-07-02T11:54:45.416000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 START RequestId: 5164ab20-3bdc-439e-811f-af13fe06a770 Version: $LATEST
2026-07-02T11:54:45.416000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA", "Host": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.13.0", "X-Amzn-Trace-Id": "Root=1-6a465185-3266443d72b842c726a55d9d", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA"], "Host": ["o5p491t2v9.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.13.0"], "X-Amzn-Trace-Id": ["Root=1-6a465185-3266443d72b842c726a55d9d"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "theo"}, "multiValueQueryStringParameters": {"name": ["theo"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "eazplx", "authorizer": {"claims": {"sub": "58e11340-10d1-701e-4cdc-41e9b488367d", "cognito:groups": "admin", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91", "version": "2", "client_id": "s148ajh0lhaib4qp3lpfcja5v", "origin_jti": "c7113241-24e8-4fee-a7b1-aaf2eb91a355", "event_id": "a3698286-776a-41fb-9cdc-8350c5e0110a", "token_use": "access", "scope": "rbac-api/admin openid rbac-api/user", "auth_time": "1782992389", "exp": "Thu Jul 02 12:39:49 UTC 2026", "iat": "Thu Jul 02 11:39:49 UTC 2026", "jti": "fd4e3e69-a231-49ba-8aa5-a5755086cda2", "username": "admin.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "f4Gs3HbOvHcEbCQ=", "requestTime": "02/Jul/2026:11:54:45 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "o5p491t2v9", "requestTimeEpoch": 1782993285142, "requestId": "a0a307b3-ba01-458d-ae55-7471d721105d", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.13.0", "user": null}, "domainName": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "deploymentId": "p4kh99", "apiId": "o5p491t2v9"}, "body": null, "isBase64Encoded": false}
2026-07-02T11:54:45.751000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 Response: {"message": "Hello theo from Python!", "timestamp": "2026-07-02T11:54:45.416764", "role": "admin"}
2026-07-02T11:54:45.772000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 END RequestId: 5164ab20-3bdc-439e-811f-af13fe06a770
2026-07-02T11:54:45.772000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 REPORT RequestId: 5164ab20-3bdc-439e-811f-af13fe06a770	Duration: 355.40 ms	Billed Duration: 356 ms	Memory Size: 128 MB	Max Memory Used: 80 MB
2026-07-02T11:54:47.618000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 START RequestId: 970d5a10-b8e3-4d10-8a58-9c9ae0a6207a Version: $LATEST
2026-07-02T11:54:47.619000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 Incoming event: {"resource": "/PythonResource", "path": "/PythonResource", "httpMethod": "GET", "headers": {"Accept": "*/*", "Authorization": "eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw", "Host": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "User-Agent": "curl/8.13.0", "X-Amzn-Trace-Id": "Root=1-6a465187-2222bd27467116ba452ad0f2", "X-Forwarded-For": "76.33.40.125", "X-Forwarded-Port": "443", "X-Forwarded-Proto": "https"}, "multiValueHeaders": {"Accept": ["*/*"], "Authorization": ["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw"], "Host": ["o5p491t2v9.execute-api.us-west-2.amazonaws.com"], "User-Agent": ["curl/8.13.0"], "X-Amzn-Trace-Id": ["Root=1-6a465187-2222bd27467116ba452ad0f2"], "X-Forwarded-For": ["76.33.40.125"], "X-Forwarded-Port": ["443"], "X-Forwarded-Proto": ["https"]}, "queryStringParameters": {"name": "denied"}, "multiValueQueryStringParameters": {"name": ["denied"]}, "pathParameters": null, "stageVariables": null, "requestContext": {"resourceId": "eazplx", "authorizer": {"claims": {"sub": "b80153d0-40f1-707b-4f10-0ab5a5e93e60", "cognito:groups": "user", "iss": "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91", "version": "2", "client_id": "s148ajh0lhaib4qp3lpfcja5v", "origin_jti": "9d5ae5c2-e64b-4f56-b9ac-32c78642fe2d", "event_id": "95a89b7d-1327-4159-8556-128ce1361fa7", "token_use": "access", "scope": "openid rbac-api/user", "auth_time": "1782992567", "exp": "Thu Jul 02 12:42:47 UTC 2026", "iat": "Thu Jul 02 11:42:47 UTC 2026", "jti": "a9918bf6-5d52-4339-81da-ea73d687c1cc", "username": "user.test"}}, "resourcePath": "/PythonResource", "httpMethod": "GET", "extendedRequestId": "f4GtPFB4vHcEMZg=", "requestTime": "02/Jul/2026:11:54:47 +0000", "path": "/prod/PythonResource", "accountId": "015195098145", "protocol": "HTTP/1.1", "stage": "prod", "domainPrefix": "o5p491t2v9", "requestTimeEpoch": 1782993287575, "requestId": "5d0eeaae-670e-4739-b775-34388df8e359", "identity": {"cognitoIdentityPoolId": null, "accountId": null, "cognitoIdentityId": null, "caller": null, "sourceIp": "76.33.40.125", "principalOrgId": null, "accessKey": null, "cognitoAuthenticationType": null, "cognitoAuthenticationProvider": null, "userArn": null, "userAgent": "curl/8.13.0", "user": null}, "domainName": "o5p491t2v9.execute-api.us-west-2.amazonaws.com", "deploymentId": "p4kh99", "apiId": "o5p491t2v9"}, "body": null, "isBase64Encoded": false}
2026-07-02T11:54:47.620000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 END RequestId: 970d5a10-b8e3-4d10-8a58-9c9ae0a6207a
2026-07-02T11:54:47.620000+00:00 2026/07/02/[$LATEST]6ddab6e6f4f44cbbb1211bf0e2ce38f2 REPORT RequestId: 970d5a10-b8e3-4d10-8a58-9c9ae0a6207a	Duration: 1.63 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 80 MB
2026-07-02T11:43:54.292000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 INIT_START Runtime Version: nodejs:24.v44	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:2cf0593e2cb85066242ca1115e05374aa5b1533615fb45cb3dd23bc8066ca239
2026-07-02T11:43:54.619000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 START RequestId: bc175a36-67b8-4794-8bd5-b0cf1553ef01 Version: $LATEST
2026-07-02T11:43:54.625000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 2026-07-02T11:43:54.625Z	bc175a36-67b8-4794-8bd5-b0cf1553ef01	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw","Host":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.13.0","X-Amzn-Trace-Id":"Root=1-6a464efa-7420fa6e5994193c2b9f7967","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw"],"Host":["nhjz4yjbdg.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.13.0"],"X-Amzn-Trace-Id":["Root=1-6a464efa-7420fa6e5994193c2b9f7967"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"xtmqzm","authorizer":{"claims":{"sub":"b80153d0-40f1-707b-4f10-0ab5a5e93e60","cognito:groups":"user","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91","version":"2","client_id":"s148ajh0lhaib4qp3lpfcja5v","origin_jti":"9d5ae5c2-e64b-4f56-b9ac-32c78642fe2d","event_id":"95a89b7d-1327-4159-8556-128ce1361fa7","token_use":"access","scope":"openid rbac-api/user","auth_time":"1782992567","exp":"Thu Jul 02 12:42:47 UTC 2026","iat":"Thu Jul 02 11:42:47 UTC 2026","jti":"a9918bf6-5d52-4339-81da-ea73d687c1cc","username":"user.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"f4FHIGqQvHcEUNw=","requestTime":"02/Jul/2026:11:43:54 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"nhjz4yjbdg","requestTimeEpoch":1782992634056,"requestId":"5f0b7e6f-dad8-4dc6-ada4-dba8640b78fd","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.13.0","user":null},"domainName":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","deploymentId":"y5gxpa","apiId":"nhjz4yjbdg"},"body":null,"isBase64Encoded":false}
2026-07-02T11:43:54.667000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 END RequestId: bc175a36-67b8-4794-8bd5-b0cf1553ef01
2026-07-02T11:43:54.667000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 REPORT RequestId: bc175a36-67b8-4794-8bd5-b0cf1553ef01	Duration: 46.76 ms	Billed Duration: 371 ms	Memory Size: 128 MB	Max Memory Used: 97 MB	Init Duration: 323.96 ms
2026-07-02T11:43:56.774000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 START RequestId: 355d781a-2944-4fe8-b9a1-1a078d3361c2 Version: $LATEST
2026-07-02T11:43:56.775000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 2026-07-02T11:43:56.775Z	355d781a-2944-4fe8-b9a1-1a078d3361c2	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA","Host":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.13.0","X-Amzn-Trace-Id":"Root=1-6a464efc-2e01e80332ea27c041a1f7cf","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA"],"Host":["nhjz4yjbdg.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.13.0"],"X-Amzn-Trace-Id":["Root=1-6a464efc-2e01e80332ea27c041a1f7cf"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"Norrin"},"multiValueQueryStringParameters":{"name":["Norrin"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"xtmqzm","authorizer":{"claims":{"sub":"58e11340-10d1-701e-4cdc-41e9b488367d","cognito:groups":"admin","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91","version":"2","client_id":"s148ajh0lhaib4qp3lpfcja5v","origin_jti":"c7113241-24e8-4fee-a7b1-aaf2eb91a355","event_id":"a3698286-776a-41fb-9cdc-8350c5e0110a","token_use":"access","scope":"rbac-api/admin openid rbac-api/user","auth_time":"1782992389","exp":"Thu Jul 02 12:39:49 UTC 2026","iat":"Thu Jul 02 11:39:49 UTC 2026","jti":"fd4e3e69-a231-49ba-8aa5-a5755086cda2","username":"admin.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"f4FHjGRjPHcEBIg=","requestTime":"02/Jul/2026:11:43:56 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"nhjz4yjbdg","requestTimeEpoch":1782992636712,"requestId":"a2258472-ebcd-4007-a420-9d94d826c059","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.13.0","user":null},"domainName":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","deploymentId":"y5gxpa","apiId":"nhjz4yjbdg"},"body":null,"isBase64Encoded":false}
2026-07-02T11:43:57.647000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 2026-07-02T11:43:57.647Z	355d781a-2944-4fe8-b9a1-1a078d3361c2	INFO	Response: {"message":"HELLO NORRIN FROM NODE!","groups":["admin"],"admin":true}
2026-07-02T11:43:57.726000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 END RequestId: 355d781a-2944-4fe8-b9a1-1a078d3361c2
2026-07-02T11:43:57.726000+00:00 2026/07/02/[$LATEST]2d142f667bd34925a99b3b851fe5d078 REPORT RequestId: 355d781a-2944-4fe8-b9a1-1a078d3361c2	Duration: 951.10 ms	Billed Duration: 952 ms	Memory Size: 128 MB	Max Memory Used: 97 MB
2026-07-02T11:54:28.488000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 INIT_START Runtime Version: nodejs:24.v44	Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:2cf0593e2cb85066242ca1115e05374aa5b1533615fb45cb3dd23bc8066ca239
2026-07-02T11:54:28.780000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 START RequestId: 2b202adc-d7fd-4bb8-b4ac-7cca9ce61b33 Version: $LATEST
2026-07-02T11:54:28.788000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 2026-07-02T11:54:28.788Z	2b202adc-d7fd-4bb8-b4ac-7cca9ce61b33	INFO	Incoming event: {}
2026-07-02T11:54:28.811000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 END RequestId: 2b202adc-d7fd-4bb8-b4ac-7cca9ce61b33
2026-07-02T11:54:28.811000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 REPORT RequestId: 2b202adc-d7fd-4bb8-b4ac-7cca9ce61b33	Duration: 30.34 ms	Billed Duration: 320 ms	Memory Size: 128 MB	Max Memory Used: 97 MB	Init Duration: 289.29 ms
2026-07-02T11:54:46.324000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 2026-07-02T11:54:46.324Z	dfada338-9e88-4380-a3d2-f5263fdc7d15	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA","Host":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.13.0","X-Amzn-Trace-Id":"Root=1-6a465186-1db843e353b5592e1d15bdd1","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI1OGUxMTM0MC0xMGQxLTcwMWUtNGNkYy00MWU5YjQ4ODM2N2QiLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbiJdLCJpc3MiOiJodHRwczovL2NvZ25pdG8taWRwLnVzLXdlc3QtMi5hbWF6b25hd3MuY29tL3VzLXdlc3QtMl8yTlp0cVVvOTEiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiJzMTQ4YWpoMGxoYWliNHFwM2xwZmNqYTV2Iiwib3JpZ2luX2p0aSI6ImM3MTEzMjQxLTI0ZTgtNGZlZS1hN2IxLWFhZjJlYjkxYTM1NSIsImV2ZW50X2lkIjoiYTM2OTgyODYtNzc2YS00MWZiLTljZGMtODM1MGM1ZTAxMTBhIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJyYmFjLWFwaS9hZG1pbiBvcGVuaWQgcmJhYy1hcGkvdXNlciIsImF1dGhfdGltZSI6MTc4Mjk5MjM4OSwiZXhwIjoxNzgyOTk1OTg5LCJpYXQiOjE3ODI5OTIzODksImp0aSI6ImZkNGUzZTY5LWEyMzEtNDliYS04YWE1LWE1NzU1MDg2Y2RhMiIsInVzZXJuYW1lIjoiYWRtaW4udGVzdCJ9.GgKYDJws8QIZQrPsLGZ5rLQ1-xNK4_fwJLT_JRWJOq5O_iXPS97yTRRdxadNH3gdaIcPPKWbMhgYxSNZEvK332lo0oStVpsY3_rSrrkSQ-8Z_39Vk0IXPsusWV922osO2bZ-HH9Pcmh5vb1ZotrTeW-OIuzJNR6LQJJgdZ97TNJD89dLhNkGmRGYBNlOUSospB70YygjXbolAxfQykFR4BgBalP3KkvrXAFY_f_JOrp1pwjcwSjBGa5lr0Njgm0igixm9zmuPicdU-_F-PMR_95uh_tAcqYHQ6u2yaszzhwLwgt6ZubXJWnFBw9A9RzRik7A_R0BRj48GPzm1-8RNA"],"Host":["nhjz4yjbdg.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.13.0"],"X-Amzn-Trace-Id":["Root=1-6a465186-1db843e353b5592e1d15bdd1"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"theo"},"multiValueQueryStringParameters":{"name":["theo"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"xtmqzm","authorizer":{"claims":{"sub":"58e11340-10d1-701e-4cdc-41e9b488367d","cognito:groups":"admin","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91","version":"2","client_id":"s148ajh0lhaib4qp3lpfcja5v","origin_jti":"c7113241-24e8-4fee-a7b1-aaf2eb91a355","event_id":"a3698286-776a-41fb-9cdc-8350c5e0110a","token_use":"access","scope":"rbac-api/admin openid rbac-api/user","auth_time":"1782992389","exp":"Thu Jul 02 12:39:49 UTC 2026","iat":"Thu Jul 02 11:39:49 UTC 2026","jti":"fd4e3e69-a231-49ba-8aa5-a5755086cda2","username":"admin.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"f4GtCEH0vHcEa-Q=","requestTime":"02/Jul/2026:11:54:46 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"nhjz4yjbdg","requestTimeEpoch":1782993286265,"requestId":"fdbbb863-8b79-4d26-8c42-acd88e913efc","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.13.0","user":null},"domainName":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","deploymentId":"y5gxpa","apiId":"nhjz4yjbdg"},"body":null,"isBase64Encoded":false}
2026-07-02T11:54:46.324000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 START RequestId: dfada338-9e88-4380-a3d2-f5263fdc7d15 Version: $LATEST
2026-07-02T11:54:47.130000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 2026-07-02T11:54:47.130Z	dfada338-9e88-4380-a3d2-f5263fdc7d15	INFO	Response: {"message":"HELLO THEO FROM NODE!","groups":["admin"],"admin":true}
2026-07-02T11:54:47.209000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 END RequestId: dfada338-9e88-4380-a3d2-f5263fdc7d15
2026-07-02T11:54:47.209000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 REPORT RequestId: dfada338-9e88-4380-a3d2-f5263fdc7d15	Duration: 884.94 ms	Billed Duration: 885 ms	Memory Size: 128 MB	Max Memory Used: 97 MB
2026-07-02T11:54:48.289000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 START RequestId: 51d0097e-a4be-40fe-891e-cfc091b6b63b Version: $LATEST
2026-07-02T11:54:48.290000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 2026-07-02T11:54:48.290Z	51d0097e-a4be-40fe-891e-cfc091b6b63b	INFO	Incoming event: {"resource":"/NodeResource","path":"/NodeResource","httpMethod":"GET","headers":{"Accept":"*/*","Authorization":"eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw","Host":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","User-Agent":"curl/8.13.0","X-Amzn-Trace-Id":"Root=1-6a465188-2b9acb91594adc3a2a2d92de","X-Forwarded-For":"76.33.40.125","X-Forwarded-Port":"443","X-Forwarded-Proto":"https"},"multiValueHeaders":{"Accept":["*/*"],"Authorization":["eyJraWQiOiJSS0V3czUzeXdvSk5IR0M3NWVtR3hrTmxwbXIzZWo0V3Y4TjkrTG5VdzNBPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiODAxNTNkMC00MGYxLTcwN2ItNGYxMC0wYWI1YTVlOTNlNjAiLCJjb2duaXRvOmdyb3VwcyI6WyJ1c2VyIl0sImlzcyI6Imh0dHBzOi8vY29nbml0by1pZHAudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vdXMtd2VzdC0yXzJOWnRxVW85MSIsInZlcnNpb24iOjIsImNsaWVudF9pZCI6InMxNDhhamgwbGhhaWI0cXAzbHBmY2phNXYiLCJvcmlnaW5fanRpIjoiOWQ1YWU1YzItZTY0Yi00ZjU2LWI5YWMtMzJjNzg2NDJmZTJkIiwiZXZlbnRfaWQiOiI5NWE4OWI3ZC0xMzI3LTQxNTktODU1Ni0xMjhjZTEzNjFmYTciLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6Im9wZW5pZCByYmFjLWFwaS91c2VyIiwiYXV0aF90aW1lIjoxNzgyOTkyNTY3LCJleHAiOjE3ODI5OTYxNjcsImlhdCI6MTc4Mjk5MjU2NywianRpIjoiYTk5MThiZjYtNWQ1Mi00MzM5LTgxZGEtZWE3M2Q2ODdjMWNjIiwidXNlcm5hbWUiOiJ1c2VyLnRlc3QifQ.IaWRI4J-u35bdply3NZwFT5O9r-Ya3pWcNG8cN-GaHrfPCZrED2g4rLBwllST_2PQ6Qt1v7V-KSlXhSzUUfFWaOAzje8ZhKYbEXkKUKhM3nm5obXxBHMzX_YevGAAoShhK4zCDb8LfGLsoxoMMDCtLE7G4Nyo3Ti8RfUtsjVBGJbyRCzYKPrpi-z1IVw1-zRqq5CpZjnJWsUaCQZIDBV7e9yiplUgj6BLErutJTu9hNOtCW0MMTMRNmw3Ydu1YrCPwKoNkY5qeWWFnsMRkRr7_y42UDX9BrT05TN6y46KIAmWxsV1XAMClugbcjSR6moYtYWn3PB8ss_rCBIHESjNw"],"Host":["nhjz4yjbdg.execute-api.us-west-2.amazonaws.com"],"User-Agent":["curl/8.13.0"],"X-Amzn-Trace-Id":["Root=1-6a465188-2b9acb91594adc3a2a2d92de"],"X-Forwarded-For":["76.33.40.125"],"X-Forwarded-Port":["443"],"X-Forwarded-Proto":["https"]},"queryStringParameters":{"name":"denied"},"multiValueQueryStringParameters":{"name":["denied"]},"pathParameters":null,"stageVariables":null,"requestContext":{"resourceId":"xtmqzm","authorizer":{"claims":{"sub":"b80153d0-40f1-707b-4f10-0ab5a5e93e60","cognito:groups":"user","iss":"https://cognito-idp.us-west-2.amazonaws.com/us-west-2_2NZtqUo91","version":"2","client_id":"s148ajh0lhaib4qp3lpfcja5v","origin_jti":"9d5ae5c2-e64b-4f56-b9ac-32c78642fe2d","event_id":"95a89b7d-1327-4159-8556-128ce1361fa7","token_use":"access","scope":"openid rbac-api/user","auth_time":"1782992567","exp":"Thu Jul 02 12:42:47 UTC 2026","iat":"Thu Jul 02 11:42:47 UTC 2026","jti":"a9918bf6-5d52-4339-81da-ea73d687c1cc","username":"user.test"}},"resourcePath":"/NodeResource","httpMethod":"GET","extendedRequestId":"f4GtVH-XvHcEi3A=","requestTime":"02/Jul/2026:11:54:48 +0000","path":"/prod/NodeResource","accountId":"015195098145","protocol":"HTTP/1.1","stage":"prod","domainPrefix":"nhjz4yjbdg","requestTimeEpoch":1782993288132,"requestId":"18c8be9e-b670-4f0d-a718-18e67ab680cd","identity":{"cognitoIdentityPoolId":null,"accountId":null,"cognitoIdentityId":null,"caller":null,"sourceIp":"76.33.40.125","principalOrgId":null,"accessKey":null,"cognitoAuthenticationType":null,"cognitoAuthenticationProvider":null,"userArn":null,"userAgent":"curl/8.13.0","user":null},"domainName":"nhjz4yjbdg.execute-api.us-west-2.amazonaws.com","deploymentId":"y5gxpa","apiId":"nhjz4yjbdg"},"body":null,"isBase64Encoded":false}
2026-07-02T11:54:48.291000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 END RequestId: 51d0097e-a4be-40fe-891e-cfc091b6b63b
2026-07-02T11:54:48.291000+00:00 2026/07/02/[$LATEST]b68a8b5f76284f5382094737865622b0 REPORT RequestId: 51d0097e-a4be-40fe-891e-cfc091b6b63b	Duration: 1.75 ms	Billed Duration: 2 ms	Memory Size: 128 MB	Max Memory Used: 97 MB
Checking API Gateway access logs...
2026-07-02T11:43:52.627000+00:00 6fc1a4f9afa885ca4d8b3dcfaf105b68 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4FG6GoQvHcEtuQ=","httpMethod":"GET","integrationLatency":"644","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"1be02043-9fd1-43a9-ace6-f4c6e4ec2603","requestTime":"02/Jul/2026:11:43:52 +0000","requestTimeEpoch":"1782992632627","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:43:55.624000+00:00 05bce31906ad74a8c6e7113ed4106854 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4FHYGbaPHcElMw=","httpMethod":"GET","integrationLatency":"366","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"92ba0ad0-5358-4ace-b64f-015c4626a9c5","requestTime":"02/Jul/2026:11:43:55 +0000","requestTimeEpoch":"1782992635624","resourcePath":"/PythonResource","responseLength":"100","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.13.0","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:44.094000+00:00 938e048323d4ebc7c85671187092a0c1 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"f4GssEp9vHcEbdQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"60838619-695e-45bc-8d3d-331626f88932","requestTime":"02/Jul/2026:11:54:44 +0000","requestTimeEpoch":"1782993284094","resourcePath":"/PythonResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:45.142000+00:00 675fdb8df587c4fb3e1854395ab20483 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4Gs3HbOvHcEbCQ=","httpMethod":"GET","integrationLatency":"366","integrationStatus":"200","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"a0a307b3-ba01-458d-ae55-7471d721105d","requestTime":"02/Jul/2026:11:54:45 +0000","requestTimeEpoch":"1782993285142","resourcePath":"/PythonResource","responseLength":"98","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:47.575000+00:00 92c02ceb545bea4a4168cb5696970e73 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4GtPFB4vHcEMZg=","httpMethod":"GET","integrationLatency":"11","integrationStatus":"403","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"5d0eeaae-670e-4739-b775-34388df8e359","requestTime":"02/Jul/2026:11:54:47 +0000","requestTimeEpoch":"1782993287575","resourcePath":"/PythonResource","responseLength":"50","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:48.684000+00:00 7acf7f23e51928a2150f1b05c27ebbfe {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"f4GtaFqHvHcEMuw=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"0afb41b6-60d7-4a56-bf47-acf1fbcabec4","requestTime":"02/Jul/2026:11:54:48 +0000","requestTimeEpoch":"1782993288684","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"4","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:49.539000+00:00 d946f8afffd193922cde61d3dc0ab8b7 {"apiId":"o5p491t2v9","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"f4GtjEsGvHcERwQ=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/PythonResource","protocol":"HTTP/1.1","requestId":"aa2c15f9-8ed3-4018-a300-c25c08f0ba24","requestTime":"02/Jul/2026:11:54:49 +0000","requestTimeEpoch":"1782993289539","resourcePath":"/PythonResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:43:54.056000+00:00 8697fe589296d6e10cfd1b5288fe83b6 {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4FHIGqQvHcEUNw=","httpMethod":"GET","integrationLatency":"572","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"5f0b7e6f-dad8-4dc6-ada4-dba8640b78fd","requestTime":"02/Jul/2026:11:43:54 +0000","requestTimeEpoch":"1782992634056","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"7","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:43:56.712000+00:00 b0a38a7a22c3edfa0dd40707c9952070 {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4FHjGRjPHcEBIg=","httpMethod":"GET","integrationLatency":"955","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"a2258472-ebcd-4007-a420-9d94d826c059","requestTime":"02/Jul/2026:11:43:56 +0000","requestTimeEpoch":"1782992636712","resourcePath":"/NodeResource","responseLength":"69","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:44.748000+00:00 ce5dff00a5a8a8c931c6f1ea4501a976 {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Unauthorized","extendedRequestId":"f4GszGiePHcEA8A=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"112162de-a0dd-4494-9c96-05fea99597b9","requestTime":"02/Jul/2026:11:54:44 +0000","requestTimeEpoch":"1782993284748","resourcePath":"/NodeResource","responseLength":"26","sourceIp":"76.33.40.125","stage":"prod","status":"401","userAgent":"curl/8.13.0","wafLatency":"7","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:46.265000+00:00 5498e122dc0c2f8e65a35306f723c96d {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4GtCEH0vHcEa-Q=","httpMethod":"GET","integrationLatency":"868","integrationStatus":"200","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"fdbbb863-8b79-4d26-8c42-acd88e913efc","requestTime":"02/Jul/2026:11:54:46 +0000","requestTimeEpoch":"1782993286265","resourcePath":"/NodeResource","responseLength":"67","sourceIp":"76.33.40.125","stage":"prod","status":"200","userAgent":"curl/8.13.0","wafLatency":"5","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:48.132000+00:00 7b303515976fd49cb85ce6a305cc9e08 {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"-","extendedRequestId":"f4GtVH-XvHcEi3A=","httpMethod":"GET","integrationLatency":"17","integrationStatus":"403","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"18c8be9e-b670-4f0d-a718-18e67ab680cd","requestTime":"02/Jul/2026:11:54:48 +0000","requestTimeEpoch":"1782993288132","resourcePath":"/NodeResource","responseLength":"49","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_ALLOW","wafStatus":"200","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:49.087000+00:00 98e6048e151c99860da75376568591ee {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"f4GteGrHPHcEVJg=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"14a47872-41f4-4a6f-8c04-a7b2e94bba72","requestTime":"02/Jul/2026:11:54:49 +0000","requestTimeEpoch":"1782993289087","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02T11:54:50.029000+00:00 b930416b1e4bcfeecf55b26cbe5511d5 {"apiId":"nhjz4yjbdg","dynamoDBErrorMessage":"-","dynamoDBItemId":"-","dynamoDBOperation":"-","dynamoDBTableName":"-","errorMessage":"Forbidden","extendedRequestId":"f4GtoHpwvHcEU3Q=","httpMethod":"GET","integrationLatency":"-","integrationStatus":"-","path":"/prod/NodeResource","protocol":"HTTP/1.1","requestId":"13c7581e-b09b-4c8e-a184-b344cbf9883b","requestTime":"02/Jul/2026:11:54:50 +0000","requestTimeEpoch":"1782993290029","resourcePath":"/NodeResource","responseLength":"23","sourceIp":"76.33.40.125","stage":"prod","status":"403","userAgent":"curl/8.13.0","wafLatency":"6","wafResponseCode":"WAF_BLOCK","wafStatus":"403","webAclArn":"arn:aws:wafv2:us-west-2:015195098145:regional/webacl/taaops-lambda-waf-cf-waf01/e08ce45f-fef1-470f-9ad4-e049ad9d3130"}
2026-07-02 02:32:50          0 AWSLogs/015195098145/
2026-07-02 04:22:46       2338 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/02/11/15/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260702T1115Z_19be8a7f.log.gz
2026-07-02 04:47:46       2573 AWSLogs/015195098145/WAFLogs/us-west-2/taaops-lambda-waf-cf-waf01/2026/07/02/11/40/015195098145_waflogs_us-west-2_taaops-lambda-waf-cf-waf01_20260702T1140Z_362a5870.log.gz

## Script Exit Summary

- Checks run: 10
- Failures: 0
- Skipped: 0
- Result: PASS

Skipping WAF CloudWatch logs check because waf_log_group output is N/A.
Wrote summary document: /c/Users/John Sweeney/aws/lambda/SEIR-Serverless-SOAR/Reports/rbac_test_report.md
RBAC_TEST_RESULT=PASS checks=10 failures=0 skipped=0
