#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import getpass
from pathlib import Path


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


def write_env_file(path, token_var_name, id_token, access_token, refresh_token):
    content = (
        f"export {token_var_name}=\"{id_token}\"\n"
        f"export ACCESS_TOKEN=\"{access_token}\"\n"
        f"export REFRESH_TOKEN=\"{refresh_token}\"\n"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def emit_tokens(args, id_token, access_token, refresh_token):
    print("\nMFA/token flow complete.")
    print(f"{args.token_var} length: {len(id_token)}")
    print(f"ACCESS_TOKEN length: {len(access_token)}")

    if args.write_env:
        env_path = Path(args.write_env)
        write_env_file(env_path, args.token_var, id_token, access_token, refresh_token)
        print(f"Wrote export file: {env_path}")
        print(f"Run: source {env_path}")
    else:
        print("\nExport commands:")
        print(f"export {args.token_var}=\"{id_token}\"")
        print(f"export ACCESS_TOKEN=\"{access_token}\"")
        if refresh_token:
            print(f"export REFRESH_TOKEN=\"{refresh_token}\"")


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
