# App Client must have no client secret.
# If Cognito says SECRET_HASH is required, this is the wrong app client ID.

import os
import json
import uuid
import hashlib
import time
import base64
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
API_PY_BASE = os.environ.get("API_PY_BASE", "")
API_NODE_BASE = os.environ.get("API_NODE_BASE", "")
bedrock = boto3.client("bedrock-runtime", region_name=REGION)


# ==================================================
# COLORS
# ==================================================

GREEN = "\033[92m"
RED = "\033[91m"
CYAN = "\033[96m"
YELLOW = "\033[93m"
RESET = "\033[0m"

# ==================================================
# JWT DECODE
# ==================================================

def decode_jwt(token):
    try:
        payload = token.split(".")[1]

        # Fix padding
        payload += '=' * (-len(payload) % 4)

        decoded = base64.urlsafe_b64decode(payload)

        return json.loads(decoded)

    except Exception as e:
        print(f"{RED}Failed to decode JWT:{RESET} {e}")
        return None

# ==================================================
# TOKEN EXPIRATION
# ==================================================

def format_expiration(exp):
    exp_time = datetime.fromtimestamp(exp, tz=timezone.utc)
    now = datetime.now(timezone.utc)

    remaining = exp_time - now

    return exp_time, remaining


# =================================================
# TOKEN TRACKING - Time-to-live (TTL) for tokens is set to 900 seconds (15 minutes) by default.
# =================================================
def _utc_iso_now():
    return datetime.now(timezone.utc).isoformat()


def _epoch_now():
    return int(time.time())


# =================================================
# TOKEN TRACKING - Hashing function for token tracking.
# =================================================
def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


# =================================================
# TOKEN TRACKING - DynamoDB tables for tracking and revocation of tokens.
# =================================================
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
        "status": "active",
        "used": False,
        "expires_at": expires_at,
        "issued_at_iso": _utc_iso_now(),
        "token_kind": "synthetic-tracking-token",
        "tracking_source": "get_token_function",
    }
    
    _tracking_table().put_item(Item=item)
    
    
    print(f"Generated token for user {username}: {raw_token}")
    
    return {
        "token_id": token_id,
        "status": "active",
        "expires_at": expires_at,
        "username": username,
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

print(f"{CYAN}")
print("========================================")
print("  GALACTUS COGNITO TOKEN RETRIEVER")
print("========================================")
print(f"{RESET}")

print(f"{YELLOW}IMPORTANT:{RESET} App Client must NOT use a client secret.\n")

def main():
    username = input("Username: ")
    password = getpass.getpass("Password: ")

    # =========================
    # Extract Tokens
    # =========================
    try:
        auth = cognito_user_password_auth(username, password)
        access_token = auth["AccessToken"]

        print(f"\n{GREEN}AUTHENTICATION SUCCESSFUL{RESET}")

        # ==================================================
        # JWT DECODE
        # ==================================================
        decoded = decode_jwt(access_token)

        if decoded:
            print(f"\n{CYAN}========== TOKEN CLAIMS =========={RESET}\n")
            print(json.dumps(decoded, indent=4))

        # ==================================================
        # GROUPS
        # ==================================================
        groups = (decoded or {}).get("cognito:groups", [])

        print(f"\n{CYAN}========== GROUP MEMBERSHIP =========={RESET}")
        if groups:
            for group in groups:
                print(f" - {group}")
        else:
            print("No groups assigned")

        # ==================================================
        # TOKEN EXPIRATION
        # ==================================================
        exp = (decoded or {}).get("exp")
        if exp:
            exp_time, remaining = format_expiration(exp)
            print(f"\n{CYAN}========== TOKEN EXPIRATION =========={RESET}")
            print(f"Expires At (UTC): {exp_time}")
            print(f"Time Remaining : {remaining}")

        # ==================================================
        # CURL EXAMPLES
        # ==================================================
        print(f"\n{CYAN}========== API TEST COMMANDS =========={RESET}\n")

        print("Python Endpoint:\n")
        print(f'''curl "{API_PY_BASE}/PythonResource" \\
  -H "Authorization: {access_token}"
''')

        print("Node Endpoint:\n")
        print(f'''curl "{API_NODE_BASE}/NodeResource" \\
  -H "Authorization: {access_token}"
''')

        print(f"\n{GREEN}Done.{RESET}\n")

    except ClientError as e:
        print(f"\n{RED}AUTHENTICATION FAILED{RESET}\n")
        message = e.response["Error"].get("Message", str(e))
        if "SECRET_HASH" in message:
            print("This app client requires a client secret.")
            print("Use a Cognito app client configured with no client secret.")
        else:
            print(message)
    except Exception as e:
        print(f"\n{RED}AUTHENTICATION FAILED{RESET}\n")
        print(str(e))


if __name__ == "__main__":
    main()
