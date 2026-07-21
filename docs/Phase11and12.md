
# Phase 11 - Serverless with MySQL
0) New Variables: Set your lab variables

export AWS_REGION="us-east-1"

# Galactus:
export DB_ID="galactus-mysql"
export DB_NAME="mysql"
export DB_USER="admin"
export SECRET_NAME="galactus-db-secret"

export LAMBDA_NAME="galactus-intake-lambda-mysql"
export API_NAME="galactus-intake-api-mysql"
export STAGE_NAME="prod"

#Galactus: Your ALB days are over. Now you suffer with VPC-enabled Lambda.
export LAMBDA_SG_NAME="galactus-lambda-sg-mysql"
export RDS_SG_NAME="galactus-rds-sg-mysql"

Verify region:

aws configure get region
       
1) VPC: RDS MySQL instance (in Default VPC)
        PubliclyAccessible = false

            aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
                  --query "DBInstances[0].PubliclyAccessible" --output text
            
            Identify Default VPC + subnets

    #CGalactus: Find the Herald’s home (default VPC).
    export VPC_ID="$(aws ec2 describe-vpcs \
      --filters Name=isDefault,Values=true \
      --query "Vpcs[0].VpcId" --output text)"
    
    echo "VPC_ID=$VPC_ID"



2) DB subnet placement
        in private subnets if available (Default VPC often has public subnets; we’ll control access via SG regardless)
    Get subnets in default VPC:

    # Galactus: Subnets are like Kashyyyk tree branches—pick a few.
    aws ec2 describe-subnets \
      --filters Name=vpc-id,Values="$VPC_ID" \
      --query "Subnets[].{SubnetId:SubnetId,Az:AvailabilityZone,Cidr:CidrBlock,MapPublic:MapPublicIpOnLaunch}" \
      --output table

Pick 2 subnets (prefer different AZs). Store them:

    export SUBNET1="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" \
      --query "Subnets[0].SubnetId" --output text)"
    export SUBNET2="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" \
      --query "Subnets[1].SubnetId" --output text)"
    
    echo "$SUBNET1 $SUBNET2"

        
3) Security groups

    RDS SG allows 3306 only from Lambda SG

        aws ec2 describe-security-groups --group-ids "$RDS_SG_ID" \
            --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\` && ToPort==\`3306\`]" --output json

    #Galactus: The database is the Taa2 Falcon. Only trusted crew allowed.
    export RDS_SG_ID="$(aws ec2 create-security-group \
      --group-name "$RDS_SG_NAME" \
      --description "RDS SG for Lab 11A" \
      --vpc-id "$VPC_ID" \
      --query "GroupId" --output text)"
    
    echo "RDS_SG_ID=$RDS_SG_ID"

Allow MySQL ONLY from Lambda SG:

    #Galactus: 3306 opens only for friends. Everyone else gets growled at and then violently humped.
    aws ec2 authorize-security-group-ingress \
      --group-id "$RDS_SG_ID" \
      --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,UserIdGroupPairs=[{GroupId=$LAMBDA_SG_ID}]"

Proof:

    aws ec2 describe-security-groups --group-ids "$RDS_SG_ID" \
      --query "SecurityGroups[0].IpPermissions" --output json

One-command “world-open?” check:

    #Galactus: If this prints FAIL, the Herald is disappointed.
    aws ec2 describe-security-groups --group-ids "$RDS_SG_ID" \
      --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\` && ToPort==\`3306\`].IpRanges[].CidrIp" \
      --output text | grep -Eq '0\.0\.0\.0/0' && echo FAIL || echo PASS
        
4) Secrets Manager secret
            JSON fields: username, password, host, port, dbname
     Create Secrets Manager secret for DB creds
Generate a strong password:

    #galactus: strong passwords make Sith cry.
    export DB_PASS="$(aws secretsmanager get-random-password \
      --password-length 24 \
      --exclude-punctuation \
      --query RandomPassword --output text)"

Create secret JSON:

#galactus: Secrets live in Secrets Manager. Not in Terraform comments. Not in Git. Not in your brain.
cat > db_secret.json <<EOF
    {
      "username": "$DB_USER",
      "password": "$DB_PASS",
      "host": "$DB_ENDPOINT",
      "port": 3306,
      "dbname": "$DB_NAME"
    }
    EOF

Create secret:

    export SECRET_ARN="$(aws secretsmanager create-secret \
      --name "$SECRET_NAME" \
      --secret-string file://db_secret.json \
      --query ARN --output text)"
    
    echo "SECRET_ARN=$SECRET_ARN"


Verify:
    aws secretsmanager describe-secret --secret-id "$SECRET_ARN" --output table

Create IAM role for Lambda
Create trust policy:

    cat > lambda_trust.json <<'EOF'
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": { "Service": "lambda.amazonaws.com" },
        "Action": "sts:AssumeRole"
      }]
    }
    EOF

Create role:

    #Galactus: Give Lambda the keys it needs, not the whole ship.
    export LAMBDA_ROLE_NAME="galactus-lambda-role-mysql"
    
    export LAMBDA_ROLE_ARN="$(aws iam create-role \
      --role-name "$LAMBDA_ROLE_NAME" \
      --assume-role-policy-document file://lambda_trust.json \
      --query Role.Arn --output text)"
    
    echo "LAMBDA_ROLE_ARN=$LAMBDA_ROLE_ARN"

Attach managed policies for logging + VPC access:

        aws iam attach-role-policy --role-name "$LAMBDA_ROLE_NAME" \
          --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        
        aws iam attach-role-policy --role-name "$LAMBDA_ROLE_NAME" \
          --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

Add inline policy to read the secret:

        cat > lambda_secret_policy.json <<EOF
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
            "Resource": "$SECRET_ARN"
          }]
        }
        EOF
        
        aws iam put-role-policy \
          --role-name "$LAMBDA_ROLE_NAME" \
          --policy-name "galactus-read-secret-11a" \
          --policy-document file://lambda_secret_policy.json
    
        
5) Lambda function (Python)
            attached to VPC subnets + Lambda SG
            environment variables set

                aws lambda get-function-configuration --function-name "$LAMBDA_NAME" \
                  --query "VpcConfig" --output json
     Build package

Create folder:

        mkdir -p lambda_pkg
        cd lambda_pkg

Install pymysql into package:

        #galactus: pymysql is pure Python. SEIR-I mercy granted.
        pip3 install pymysql -t .

Create lambda_function.py:

https://github.com/BalericaAI/armageddon/blob/main/SEIR_Foundations/lab11/lambda/lambda_function.py

        cat > lambda_function.py <<'EOF'

Zip it:

        zip -r ../galactus_lambda_11a.zip . >/dev/null
        cd ..

Create Lambda function

        aws lambda create-function \
          --function-name "$LAMBDA_NAME" \
          --runtime python3.12 \
          --handler lambda_function.lambda_handler \
          --zip-file "fileb://galactus_lambda_11a.zip" \
          --role "$LAMBDA_ROLE_ARN" \
          --timeout 10 \
          --memory-size 256 \
          --environment "Variables={DB_SECRET_ARN=$SECRET_ARN,DB_NAME=$DB_NAME,DB_CONNECT_TIMEOUT=5}" \
          --vpc-config "SubnetIds=$SUBNET1,$SUBNET2,SecurityGroupIds=$LAMBDA_SG_ID" \
          --region "$AWS_REGION"

Verify config:

    #galactus: If VpcConfig is empty, the Wookiee throws the console at you.
aws lambda get-function-configuration --function-name "$LAMBDA_NAME" \
  --query "{Runtime:Runtime,VpcConfig:VpcConfig,Env:Environment.Variables}" --output json


6) API Gateway
            POST /intake integration to Lambda

                aws apigatewayv2 get-routes --api-id "$API_ID" --output table

    Create API:

        export API_ID="$(aws apigatewayv2 create-api \
          --name "$API_NAME" \
          --protocol-type HTTP \
          --query ApiId --output text)"
        
        echo "API_ID=$API_ID"

Create integration (Lambda proxy):

        export INTEGRATION_ID="$(aws apigatewayv2 create-integration \
          --api-id "$API_ID" \
          --integration-type AWS_PROXY \
          --integration-uri "arn:aws:lambda:$AWS_REGION:$account_id:function:$LAMBDA_NAME" \
          --payload-format-version "2.0" \
          --query IntegrationId --output text)"
        
        echo "INTEGRATION_ID=$INTEGRATION_ID"

Create route:

        aws apigatewayv2 create-route \
          --api-id "$API_ID" \
          --route-key "POST /intake" \
          --target "integrations/$INTEGRATION_ID"

Create stage:

        aws apigatewayv2 create-stage --api-id "$API_ID" --stage-name "$STAGE_NAME" --auto-deploy

Allow API Gateway to invoke Lambda:

        #galactus: API Gateway must be allowed to puke on the Wookiee.
        aws lambda add-permission \
          --function-name "$LAMBDA_NAME" \
          --statement-id "apigw-invoke-11a" \
          --action lambda:InvokeFunction \
          --principal apigateway.amazonaws.com \
          --source-arn "arn:aws:execute-api:$AWS_REGION:$account_id:$API_ID/*/*/intake"

Invoke URL:

        export INVOKE_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${STAGE_NAME}/intake"
        echo "$INVOKE_URL"



7) Database table
            audit_events created
    Note: In default VPC you can still make RDS private (PubliclyAccessible=false). Do that.
Create DB subnet group (using two subnets):
```
    # galactus: “Subnet group” = Falcon docking permissions.
    aws rds create-db-subnet-group \
      --db-subnet-group-name "galactus-dbsubnet-11a" \
      --db-subnet-group-description "Lab 11A subnet group" \
      --subnet-ids "$SUBNET1" "$SUBNET2"
```

Create DB:

Table:
  CREATE TABLE audit_events (
    id VARCHAR(36) PRIMARY KEY,
    ts_utc VARCHAR(30) NOT NULL,
    actor VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    resource VARCHAR(200) NOT NULL,
    note VARCHAR(500),
    source_ip VARCHAR(60),
    request_id VARCHAR(100)
  );


    #Galactus: This is where student tears are stored.
    aws rds create-db-instance \
      --db-instance-identifier "$DB_ID" \
      --engine mysql \
      --db-instance-class db.t3.micro \
      --allocated-storage 20 \
      --master-username "$DB_USER" \
      --master-user-password "TEMPORARY_PASSWORD_LIZZO_LUVS_YOU" \
      --vpc-security-group-ids "$RDS_SG_ID" \
      --db-subnet-group-name "galactus-dbsubnet-11a" \
      --backup-retention-period 0 \
      --no-publicly-accessible \
      --region "$AWS_REGION"

Wait until available:

    aws rds wait db-instance-available --db-instance-identifier "$DB_ID" --region "$AWS_REGION"
    echo "RDS is available."

Get endpoint:

    export DB_ENDPOINT="$(aws rds describe-db-instances \
      --db-instance-identifier "$DB_ID" \
      --query "DBInstances[0].Endpoint.Address" --output text)"
    
    echo "DB_ENDPOINT=$DB_ENDPOINT"

Verify it’s private:
```
# Galactus: “PubliclyAccessible: False” or the Wookiee rips your arm off.
aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query "DBInstances[0].PubliclyAccessible" --output text
```

Create database + table (one-time)
You need a MySQL client from somewhere that can reach the DB. For Lab 11A, easiest is:
    CloudShell (if it can reach, depends on networking) or
    a temporary EC2 in the VPC or   your own bastion/VPN setup


Once connected:
```
    CREATE DATABASE lab11;
    USE lab11;
    
    CREATE TABLE audit_events (
      id VARCHAR(36) PRIMARY KEY,
      ts_utc VARCHAR(30) NOT NULL,
      actor VARCHAR(100) NOT NULL,
      action VARCHAR(50) NOT NULL,
      resource VARCHAR(200) NOT NULL,
      note VARCHAR(500),
      source_ip VARCHAR(60),
      request_id VARCHAR(100)
    );
```
        
8) Proof artifacts
```
   CLI outputs + a successful curl that inserts a row
```

9) Cloudwatch Logs
```
                aws logs describe-log-streams --log-group-name "/aws/lambda/$LAMBDA_NAME" \
                  --order-by LastEventTime --descending --max-items 1 --output table
```

10) Test it (curl) + prove insert

Invoke:
```
        # galactus: If this returns DB_WRITE_FAILED, your networking is wrong and you win Lizzo. Good. Learn it.
        curl -sS -X POST "$INVOKE_URL" \
          -H "content-type: application/json" \
          -d '{"actor":"doctor.ny","action":"VIEW_PATIENT","resource":"patient/12345","note":"Viewed chart"}'
```

Watch logs:
```
        # galactus watching you.... 
        aws logs tail "/aws/lambda/$LAMBDA_NAME" --since 10m --follow
```

DB proof (from your MySQL client):
```
        SELECT * FROM audit_events ORDER BY ts_utc DESC LIMIT 5;
```

## 11B - Incident Response (Lambda + API Gateway + RDS)

“The system doesn’t need heroes.
It needs adults.”

What this lab is

Phase 11B simulates a real production incident in a serverless system:

Client → API Gateway → Lambda → RDS

Something breaks.
Not “the whole system.”
One small thing.

Your job is not to panic, redeploy everything, or guess.

Your job is to:
    1. Prove the failure
    2. Collect evidence
    3. Identify the root cause
    4. Recover the system
    5. Prove recovery
    6. Document what happened

That’s it.

This lab does not test how fast you type.
It tests whether you can think clearly under pressure.

Why we are doing this

Most outages are not caused by “bad code.”

They are caused by:
    a missing security-group rule
    a rotated secret
    a wrong environment variable
    a VPC attachment mistake

In serverless systems, you cannot SSH in and poke around.
So your only tools are:
    logs
    configuration
    evidence
    discipline

This lab trains the exact mindset used by:
    Cloud engineers on call
    Incident commanders
    Audit-facing platform teams
    Regulated environments (healthcare, finance, gov)

What “passing” actually means
You do not pass by fixing the issue alone.
You pass only if you can prove, with evidence:
    the system was healthy
    the system failed
    why it failed
    what you changed
    that it is healthy again

That is what separates:

“I fixed it”
from
“I can defend this in front of auditors”

Required: evidence_manifest.json

    Every Lab 11B submission must include an evidence manifest.
    
    This is non-negotiable.
    
    Purpose
    
    The manifest proves:
        what evidence exists
        when it was collected
        that it was not altered
    
    This is how audits, SOC reports, and post-incident reviews work in real companies.

Required location

    evidence_11b/evidence_manifest.json

Required structure

{
  "schema_version": "1.0",
  "lab": "SEIR-I Lab 11B",
  "generated_utc": "2026-01-02T03:14:15Z",
  "student": {
    "name": "",
    "email": "",
    "class": "SEIR-I"
  },
  "incident": {
    "type": "Lambda-RDS connectivity failure",
    "injected_by": "security_group | secret | unknown",
    "initial_symptom": "API returned non-200"
  },
  "evidence_files": [
    {
      "file": "invoke_baseline.json",
      "sha256": "REPLACE_ME"
    },
    {
      "file": "invoke_failure.json",
      "sha256": "REPLACE_ME"
    },
    {
      "file": "invoke_recovery.json",
      "sha256": "REPLACE_ME"
    },
    {
      "file": "logs_tail.out",
      "sha256": "REPLACE_ME"
    },
    {
      "file": "sg_before_revoke_3306.out",
      "sha256": "REPLACE_ME"
    },
    {
      "file": "sg_after_restore.out",
      "sha256": "REPLACE_ME"
    }
  ]
}


YOU must compute hashes yourself:

sha256sum evidence_11b/* > evidence_11b/hashes.txt

Then copy the correct values into the manifest.

Why this matters:
Auditors assume logs can lie.
Hashes don’t.

Required: Human Notes (No Automation Allowed)

    Automation proves what happened.
    Humans must explain why.
    
    Every student must submit a short written file:

      human_notes_11b.md


Required template

# SEIR-I Phase 11B — Human Incident Notes

## 1. What was the initial symptom?
(What did the user/system experience?)

## 2. What evidence showed the system was failing?
(List specific files, logs, HTTP codes, timestamps.)

## 3. What was the root cause?
(Be precise. One sentence.)

## 4. What change fixed the issue?
(Exactly what was modified.)

## 5. How did you verify recovery?
(What evidence proves it is working again?)

## 6. What would you monitor next time to catch this faster?
(Logs, metrics, alarms.)

No bullet-point fluff.
No guessing.
No blame.

Just facts.

Why this matters for your career

At 2 a.m., nobody cares:
    what tutorial you followed
    what cert you memorized

They care whether you can:
    stay calm
    collect evidence
    fix one thing
    explain it clearly


# Phase 12 - New Agents and MCP

Architecture:

  WAF Telemetry
     ↓
  Threat Correlation Agent
     ↓
  Finding stored
     ↓
  EventBridge custom event
     ↓
  SOAR Response Agent
     ├── Get finding
     ├── Validate status
     ├── Select playbook
     ├── Generate Bedrock summaries
     ├── Send SNS notification
     ├── Create incident record
     └── Update finding status
              ↓
       Human analyst review
              ↓
     Future containment workflow



        AWS WAF
           ↓
        CloudWatch Logs
           ↓
        WAF Bedrock Analyzer
           ↓
        DynamoDB: waf-events
           ↓
        Threat Correlation Agent
           ↓
        DynamoDB: waf-correlation-findings
           ↓
        EventBridge Custom Event
           ↓
        SOAR Response Agent
           ├── Validate finding
           ├── Select response playbook
           ├── Send notifications
           ├── Create response record
           ├── Request human approval when needed
           └── Perform approved containment actions

  ## SOAR Response Agent
  soar_response_agent.py
  ```
     Receive a threat-finding event from EventBridge.
    Retrieve the complete finding from DynamoDB.
    Validate that the finding has not already been processed.
    Select a deterministic response playbook.
    Ask Bedrock to create analyst and management summaries.
    Create an incident record.
    Publish an SNS notification.
    Update the original finding’s workflow status.
```


Main responsibilities

Retrieve and validate the finding
The EventBridge event should contain only routing information.

Agent should retrieve the complete record from: waf-correlation-findings using finding_id.

This ensures the agent operates on the full stored evidence rather than trusting a small event payload.

It should verify:
```
the finding exists
status is still OPEN
it has not already been processed
severity is valid
required evidence is present
```

2. Select a playbook

The playbook selection should be deterministic.

Example:


| Severity | Playbook                                              |
| -------- | ----------------------------------------------------- |
| Low      | Record only                                           |
| Medium   | Notify analyst                                        |
| High     | Notify and create incident                            |
| Critical | Notify, create incident, request containment approval |


SOAR execution record
Required DynamoDB tables

        waf-correlation-findings
        Primary key: finding_id
        
        security-incidents
        Primary key: incident_id



Required environment variables

        CORRELATION_FINDINGS_TABLE=waf-correlation-findings
        SECURITY_INCIDENTS_TABLE=security-incidents
        SNS_TOPIC_ARN=<SNS topic ARN>
        BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0
        ENABLE_BEDROCK=true

Expected EventBridge input

        {
          "version": "0",
          "id": "example-event-id",
          "detail-type": "WAF Threat Finding Created",
          "source": "seir.waf.correlation",
          "account": "123456789012",
          "time": "2026-07-14T20:10:00Z",
          "region": "us-east-1",
          "resources": [],
          "detail": {
            "finding_id": "7ea476d0-1fea-4ff0-a95a-6377faac5cb4",
            "severity": "HIGH",
            "risk_score": 75
          }
        }


EventBridge events use a standard JSON envelope with fields such as source, detail-type, and detail; this agent uses only detail.finding_id for routing, then retrieves the authoritative finding from DynamoDB.

Required IAM actions

        {
          "Effect": "Allow",
          "Action": [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "sns:Publish",
            "bedrock:InvokeModel"
          ],
          "Resource": "*"
        }

How would you implement:

        logs:CreateLogStream
        logs:PutLogEvents
        events:PutEvents


These map directly to the agent’s responsibilities: retrieve the finding, create the incident, update workflow state, publish the notification, and request informational Bedrock inference. Bedrock model invocation requires bedrock:InvokeModel; DynamoDB’s resource interface supports retrieving, writing, and modifying table items.


The deterministic incident ID: INC-<finding_id> makes the workflow idempotent when EventBridge retries the same finding. The conditional DynamoDB write prevents an existing incident from being replaced accidentally. DynamoDB supports conditional puts for this exact create-only pattern.

## Eventbride Outing rules:
Medium and High

    {
      "source": ["seir.waf.correlation"],
      "detail-type": ["WAF Threat Finding Created"],
      "detail": {
        "severity": ["MEDIUM", "HIGH"]
      }
    }

  Target: soar-response-agent

  Critical

      {
      "source": ["seir.waf.correlation"],
      "detail-type": ["WAF Threat Finding Created"],
      "detail": {
        "severity": ["CRITICAL"]
      }
    }

  Targets:

      soar-response-agent
      critical-alert SNS topic


Required dependency

Create requirements.txt:


    reportlab==4.4.3

ReportLab is not included in the standard Lambda runtime. It must be packaged with the deployment ZIP or supplied as a Lambda layer. Lambda layers can carry third-party Python dependencies, and their contents must be compatible with the Lambda Linux runtime.

Required environment variables

    WAF_EVENTS_TABLE=waf-events
    CORRELATION_FINDINGS_TABLE=waf-correlation-findings
    SECURITY_INCIDENTS_TABLE=security-incidents
    
    REPORT_BUCKET=galactus-s3-123456789012
    REPORT_PREFIX=executive-reports
    
    BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0
    ENABLE_BEDROCK=true
    
    REPORT_PERIOD_HOURS=24
    MAX_ITEMS_PER_TABLE=5000
    
    ORGANIZATION_NAME=SEIR Cloud Security
    REPORT_TITLE=Executive Security Report

  Required IAM permissions


        {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "ReadSecurityData",
          "Effect": "Allow",
          "Action": [
            "dynamodb:Scan"
          ],
          "Resource": [
            "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/waf-events",
            "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/waf-correlation-findings",
            "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/security-incidents"
          ]
        },
        {
          "Sid": "InvokeBedrock",
          "Effect": "Allow",
          "Action": [
            "bedrock:InvokeModel"
          ],
          "Resource": "*"
        },
        {
          "Sid": "WriteExecutiveReports",
          "Effect": "Allow",
          "Action": [
            "s3:PutObject"
          ],
          "Resource": [
            "arn:aws:s3:::galactus-s3-123456789012/executive-reports/*"
          ]
        }
      ]
    }


bedrock:InvokeModel authorizes the model inference call, while S3 PutObject writes the complete PDF and JSON objects to the bucket.

S3 output layout

The code produces:


        galactus-s3-123456789012/
        └── executive-reports/
            └── 2026/
                └── 07/
                    └── 14/
                        ├── pdf/
                        │   └── executive-security-20260714T230000Z.pdf
                        └── json/
                            └── executive-security-20260714T230000Z.json

Both objects come from the same report document, so the PDF and JSON should contain synchronized facts.

Lambda test event

        {
          "report_period_hours": 24
        }

Lambda configuration

        Memory: 1024 MB
        Timeout: 120 seconds
        Ephemeral storage: 512 MB

This implementation creates the PDF in memory, so it does not require /tmp. Lambda does provide configurable /tmp storage from 512 MB through 10,240 MB when later revisions need temporary chart images or larger report artifacts.
