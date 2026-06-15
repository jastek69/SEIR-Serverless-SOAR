#!/usr/bin/env python3

# This script is for testing purposes only and should be used with caution. It is designed to help users who are in the MFA_SETUP state in AWS Cognito to complete their MFA setup and obtain tokens for testing or bootstrapping other tools. The script interacts with AWS Cognito using the AWS CLI, so it requires that the AWS CLI is installed and configured properly on the system where it is run.
# The boostrap process is intended to be a one-time setup for users who are in the MFA_SETUP state. It guides the user through the necessary steps to complete MFA setup, including handling the SOFTWARE_TOKEN_MFA challenge if the user has already completed MFA setup but is still being challenged. The script also includes an option to send the MFA secret via email using AWS SES, which is intended for testing purposes only and should be used with caution in production environments.
# The script performs the following steps:
# 1. Prompts the user for their Cognito password (if not provided via command-line argument).
# 2. Initiates authentication with Cognito using the USER_PASSWORD_AUTH flow.
# 3. If the user is already authenticated without any challenges, it outputs the tokens.
# 4. If the user is challenged with SOFTWARE_TOKEN_MFA, it prompts for the current TOTP code and responds to the challenge to obtain tokens.
# 5. If the user is in MFA_SETUP, it initiates the MFA setup process, displays the new MFA secret, optionally sends it via email using AWS SES, prompts for the TOTP code to verify and complete setup, and then obtains tokens.
#
# This script is a one-time helper for users in MFA_SETUP state in Cognito. It performs the necessary steps to complete MFA setup and obtain tokens, which can then be used for testing or bootstrapping other tools.
# Usage example:
#   python mfa_bootstrap.py --username admin.test --send-secret-to admin.test@example.com


import argparse
import base64
import hashlib
import hmac
import json
import os
import subprocess
import time
import struct
import sys
import getpass
from pathlib import Path

# Definitions:


# The script will prompt for the Cognito password (if not provided via --password), then guide the user through the MFA setup process. If the user is already in MFA_SETUP, it will prompt for the current TOTP code. If not, it will initiate MFA setup, display the new secret, optionally email it via SES, and then prompt for the TOTP code to verify and complete setup. Finally, it will output export commands for the obtained tokens or write them to an env file if --write-env is specified.

# subprocess will be used to process AWS CLI commands for Cognito interactions and SES email sending. All commands will capture stdout and stderr to provide clear error messages if any step fails. The script will handle various edge cases, such as missing tokens in responses or unsupported challenge types, and will print informative messages throughout the process.
# stdout and stderr will be captured to provide clear error messages if any command fails.
def run_cmd(args):
    proc = subprocess.run(args, capture_output=True, text=True)
    if proc.returncode != 0:
        stderr = proc.stderr.strip() or "<no stderr>"
        stdout = proc.stdout.strip()
        if stdout:
            stderr = f"{stderr}\n{stdout}"
        raise RuntimeError(f"Command failed ({' '.join(args)}):\n{stderr}")
    return proc.stdout.strip()


def get_terraform_output(name):
    return run_cmd(["terraform", "output", "-raw", name]).strip()

# THIS IS ONLY FOR TESTING PURPOSES. In production, MFA secrets should be handled with extreme care and not sent via email.
# Send email via AWS SES with the MFA secret code with a warning about the sensitivity of the information. The email will include the username and the secret code, and will advise the recipient to delete the email after use.
def send_secret_email(secret_code, username, to_email, from_email, region):
    subject = f"Cognito MFA setup secret for {username}"
    body = (
        "Use this temporary MFA secret for initial authenticator setup.\n\n"
        f"Username: {username}\n"
        f"Secret: {secret_code}\n\n"
        "Important: this secret grants generation of valid MFA codes.\n"
        "After setup, delete this email where possible."
    )
    run_cmd(
        [
            "aws",
            "ses",
            "send-email",
            "--region",
            region,
            "--from",
            from_email,
            "--destination",
            f"ToAddresses={to_email}",
            "--message",
            f"Subject={{Data={subject},Charset=UTF-8}},Body={{Text={{Data={body},Charset=UTF-8}}}}",
        ]
    )

# Writes an env file with export lines for the ID token, access token, and refresh token (if present).
def decode_jwt_claims(token):
    parts = token.split(".")
    if len(parts) != 3:
        raise RuntimeError("Cognito ID token is not a valid JWT")
    payload = parts[1] + ("=" * (-len(parts[1]) % 4))
    return json.loads(base64.urlsafe_b64decode(payload.encode("ascii")).decode("utf-8"))


def register_token_tracking(id_token, username, region):
    claims = decode_jwt_claims(id_token)
    token_id = claims.get("jti") or claims.get("origin_jti")
    issued_at = int(claims.get("iat", 0))
    expires_at = int(claims.get("exp", 0))
    if not token_id or not issued_at or not expires_at:
        raise RuntimeError("Cognito ID token is missing jti/origin_jti, iat, or exp claims")

    issued_at_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(issued_at))
    item = {
        "token_id": {"S": token_id},
        "token_hash": {"S": hashlib.sha256(id_token.encode("utf-8")).hexdigest()},
        "username": {"S": username},
        "status": {"S": "active"},
        "used": {"BOOL": False},
        "expires_at": {"N": str(expires_at)},
        "issued_at_iso": {"S": issued_at_iso},
        "token_kind": {"S": "cognito-id-token"},
        "tracking_source": {"S": "mfa-bootstrap"},
    }
    run_cmd(
        [
            "aws",
            "dynamodb",
            "put-item",
            "--table-name",
            "token-tracking",
            "--item",
            json.dumps(item, separators=(",", ":")),
            "--region",
            region,
        ]
    )
    return token_id


def write_env_file(path, token_var_name, id_token, access_token, refresh_token, tracking_id=""):
    content = (
        f"export {token_var_name}=\"{id_token}\"\n"
        f"export ACCESS_TOKEN=\"{access_token}\"\n"
        f"export REFRESH_TOKEN=\"{refresh_token}\"\n"
        f"export {token_var_name}_TRACKING_ID=\"{tracking_id}\"\n"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")

# Prints token info and either writes to an env file or prints export commands to stdout.
def emit_tokens(args, id_token, access_token, refresh_token):
    print("\nMFA/token flow complete.")
    print(f"{args.token_var} length: {len(id_token)}")
    print(f"ACCESS_TOKEN length: {len(access_token)}")

    tracking_id = ""
    if args.track_token:
        tracking_id = register_token_tracking(id_token, args.username, args.region)
        print(f"Registered Cognito JWT tracking ID: {tracking_id}")

    if args.write_env:
        env_path = Path(args.write_env)
        write_env_file(
            env_path,
            args.token_var,
            id_token,
            access_token,
            refresh_token,
            tracking_id,
        )
        print(f"Wrote export file: {env_path}")
        print(f"Run: source {env_path}")
    else:
        print("\nExport commands:")
        print(f"export {args.token_var}=\"{id_token}\"")
        print(f"export ACCESS_TOKEN=\"{access_token}\"")
        if refresh_token:
            print(f"export REFRESH_TOKEN=\"{refresh_token}\"")
        if tracking_id:
            print(f"export {args.token_var}_TRACKING_ID=\"{tracking_id}\"")


def generate_totp(secret_code, for_time=None, interval=30, digits=6):
    if for_time is None:
        for_time = int(time.time())
    normalized = secret_code.strip().replace(" ", "")
    missing_padding = (-len(normalized)) % 8
    if missing_padding:
        normalized = normalized + ("=" * missing_padding)
    key = base64.b32decode(normalized, casefold=True)
    counter = struct.pack(">Q", int(for_time // interval))
    digest = hmac.new(key, counter, hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    code_int = struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7FFFFFFF
    code = code_int % (10 ** digits)
    return f"{code:0{digits}d}"

# Define the boostrap process in the main function, which will handle the command-line arguments, perform the Cognito authentication and MFA setup flow, and emit the obtained tokens. The main function will also include error handling to catch and display any exceptions that occur during the process.
def main():
    parser = argparse.ArgumentParser(description="One-time Cognito MFA_SETUP bootstrap helper")
    parser.add_argument("--username", required=True, help="Cognito username, e.g. admin.test")
    parser.add_argument("--password", default="", help="Cognito password. If omitted, you will be prompted securely")
    parser.add_argument("--region", default=os.environ.get("AWS_REGION", "us-west-2"), help="AWS region")
    parser.add_argument("--client-id", default="", help="Cognito app client id. If omitted, loads from terraform output cognito_user_pool_client_id")
    parser.add_argument("--device-name", default="mfa-bootstrap-device", help="Friendly device name")
    parser.add_argument("--token-var", default="ID_TOKEN", help="Env var name for ID token in output file")
    parser.add_argument("--write-env", default="", help="Optional file path to write export lines")
    parser.add_argument("--send-secret-to", default="", help="Optional email address to send MFA secret via SES")
    parser.add_argument("--ses-from", default="", help="SES from address. Defaults to --send-secret-to when omitted")
    parser.add_argument("--auto-totp", action="store_true", help="Generate TOTP automatically during MFA_SETUP using the Cognito secret")
    parser.add_argument("--track-token", action="store_true", help="Register the Cognito ID token metadata in DynamoDB token-tracking")
    args = parser.parse_args()

    try:
        client_id = args.client_id or get_terraform_output("cognito_user_pool_client_id")
        password = args.password or getpass.getpass("Cognito password: ")
        if not password:
            raise RuntimeError("Password is required")

        print(f"Using region: {args.region}")
        print(f"Using client id: {client_id}")
        print(f"Username: {args.username}")

        init_raw = run_cmd([
            "aws",
            "cognito-idp",
            "initiate-auth",
            "--client-id",
            client_id,
            "--auth-flow",
            "USER_PASSWORD_AUTH",
            "--auth-parameters",
            f"USERNAME={args.username},PASSWORD={password}",
            "--region",
            args.region,
            "--output",
            "json",
        ])
        init = json.loads(init_raw)

        # Already authenticated with no challenge.
        if "AuthenticationResult" in init:
            auth = init.get("AuthenticationResult", {})
            id_token = auth.get("IdToken", "")
            access_token = auth.get("AccessToken", "")
            refresh_token = auth.get("RefreshToken", "")
            if not id_token or not access_token:
                raise RuntimeError("No IdToken/AccessToken returned from initiate-auth")
            emit_tokens(args, id_token, access_token, refresh_token)
            return

        challenge_name = init.get("ChallengeName", "")
        session = init.get("Session", "")

        if not session:
            raise RuntimeError("initiate-auth returned empty Session")

        # Common path for users that already completed MFA setup.
        if challenge_name == "SOFTWARE_TOKEN_MFA":
            totp_code = input("Enter current 6-digit TOTP code: ").strip()
            if not totp_code:
                raise RuntimeError("No TOTP code provided")

            auth_raw = run_cmd([
                "aws",
                "cognito-idp",
                "respond-to-auth-challenge",
                "--client-id",
                client_id,
                "--challenge-name",
                "SOFTWARE_TOKEN_MFA",
                "--session",
                session,
                "--challenge-responses",
                f"USERNAME={args.username},SOFTWARE_TOKEN_MFA_CODE={totp_code}",
                "--region",
                args.region,
                "--output",
                "json",
            ])
            auth = json.loads(auth_raw).get("AuthenticationResult", {})
            id_token = auth.get("IdToken", "")
            access_token = auth.get("AccessToken", "")
            refresh_token = auth.get("RefreshToken", "")
            if not id_token or not access_token:
                raise RuntimeError("No IdToken/AccessToken returned from SOFTWARE_TOKEN_MFA challenge")
            emit_tokens(args, id_token, access_token, refresh_token)
            return

        if challenge_name and challenge_name != "MFA_SETUP":
            raise RuntimeError(f"Unsupported Cognito challenge: {challenge_name}")

        assoc_raw = run_cmd([
            "aws",
            "cognito-idp",
            "associate-software-token",
            "--session",
            session,
            "--region",
            args.region,
            "--output",
            "json",
        ])
        assoc = json.loads(assoc_raw)
        secret_code = assoc.get("SecretCode", "")
        mfa_setup_session = assoc.get("Session", "")

        if not secret_code or not mfa_setup_session:
            raise RuntimeError("associate-software-token did not return SecretCode and Session")

        print("\nAdd this NEW secret to your authenticator app (replace old entry):")
        print(secret_code)
        if args.send_secret_to:
            sender = args.ses_from or args.send_secret_to
            send_secret_email(secret_code, args.username, args.send_secret_to, sender, args.region)
            print(f"Secret email sent to: {args.send_secret_to}")
        if args.auto_totp:
            # Use a just-rolled window so the generated code has maximum remaining lifetime.
            now = int(time.time())
            wait_seconds = 30 - (now % 30)
            if wait_seconds <= 2:
                time.sleep(wait_seconds + 1)
            totp_code = generate_totp(secret_code)
            print("Auto-generated TOTP for MFA setup and submitting immediately.")
        else:
            print("Then wait for a fresh 30-second code window and enter it immediately.\n")
            totp_code = input("Enter current 6-digit TOTP code: ").strip()
            if not totp_code:
                raise RuntimeError("No TOTP code provided")

        verify_raw = run_cmd([
            "aws",
            "cognito-idp",
            "verify-software-token",
            "--session",
            mfa_setup_session,
            "--user-code",
            totp_code,
            "--friendly-device-name",
            args.device_name,
            "--region",
            args.region,
            "--output",
            "json",
        ])
        verify = json.loads(verify_raw)
        status = verify.get("Status", "")
        verify_session = verify.get("Session", "")

        if status != "SUCCESS" or not verify_session:
            raise RuntimeError(f"verify-software-token did not succeed. Status={status}")

        auth_raw = run_cmd([
            "aws",
            "cognito-idp",
            "respond-to-auth-challenge",
            "--client-id",
            client_id,
            "--challenge-name",
            "MFA_SETUP",
            "--session",
            verify_session,
            "--challenge-responses",
            f"USERNAME={args.username}",
            "--region",
            args.region,
            "--output",
            "json",
        ])
        auth = json.loads(auth_raw).get("AuthenticationResult", {})

        id_token = auth.get("IdToken", "")
        access_token = auth.get("AccessToken", "")
        refresh_token = auth.get("RefreshToken", "")

        if not id_token or not access_token:
            raise RuntimeError("No IdToken/AccessToken returned from respond-to-auth-challenge")

        emit_tokens(args, id_token, access_token, refresh_token)

    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
