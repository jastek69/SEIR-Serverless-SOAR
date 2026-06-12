# App Client must have no client secret.
# If Cognito says SECRET_HASH is required, this is the wrong app client ID.

import os
import json
import uuid
import hashlib
import time
from datetime import datetime, timezone
import boto3
import getpass
from botocore.exceptions import ClientError

# =========================
# Configuration
# =========================

CLIENT_ID = os.environ.get("COGNITO_APP_CLIENT_ID", "")
REGION = os.environ.get("AWS_REGION", "us-west-2")
TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
bedrock = boto3.client("bedrock-runtime", region_name=REGION)

def _utc_iso_now():
    return datetime.now(timezone.utc).isoformat()


def _epoch_now():
    return int(time.time())


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _tracking_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(TRACKING_TABLE)


def invoke_bedrock_prompt(prompt: str, model_id: str = "anthropic.claude-v4"):
    return bedrock.invoke_model(
        modelId=model_id,
        body=json.dumps(
            {
                "prompt": prompt,
                "max_tokens_to_sample": 300,
            }
        ),
    )


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

# =========================
# Cognito Client - Define Cognito User Password Auth Function
# =========================
def cognito_user_password_auth(username: str, password: str):
    if not CLIENT_ID:
        raise RuntimeError("Missing COGNITO_APP_CLIENT_ID environment variable")

    client = boto3.client("cognito-idp", region_name=REGION)

    response = client.initiate_auth(
        ClientId=CLIENT_ID,
        AuthFlow="USER_PASSWORD_AUTH",
        AuthParameters={"USERNAME": username, "PASSWORD": password},
    )

    # =========================
    # Handle MFA Challenge
    # =========================
    challenge_name = response.get("ChallengeName")

    if challenge_name in ("SMS_MFA", "SOFTWARE_TOKEN_MFA"):
        code = input("Enter MFA Code: ")
        code_key = "SMS_MFA_CODE" if challenge_name == "SMS_MFA" else "SOFTWARE_TOKEN_MFA_CODE"
        challenge_responses = {
            "USERNAME": username,
            code_key: code
        }

        response = client.respond_to_auth_challenge(
            ClientId=CLIENT_ID,
            ChallengeName=challenge_name,
            Session=response["Session"],
            ChallengeResponses=challenge_responses
        )
    elif challenge_name:
        raise RuntimeError(f"Unsupported Cognito challenge: {challenge_name}")

    return response["AuthenticationResult"]


# =========================
# Lambda Handler for token tracking and issuance - a serverless environment to track token usage and expiration.
# tracking function = writes token metadata to DynamoDB, 
# including a hashed version of the token for later validation.
# Returns the raw token to the caller.
# =========================
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

# =========================
# Main function for command-line usage to authenticate user and print tokens, which can be used for testing or manual token retrieval.
# =========================
def main():
    username = input("Username: ")
    password = getpass.getpass("Password: ")

    # =========================
    # Extract Tokens
    # =========================
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