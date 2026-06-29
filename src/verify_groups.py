import base64
import json

from token_tracking import mark_token_used

# ==================================================
# JWT Decode Function
# ==================================================

def decode_jwt(token):

    try:
        parts = token.split(".")

        if len(parts) != 3:
            raise Exception("Invalid JWT format")

        payload = parts[1]

        # Fix Base64 padding
        payload += '=' * (-len(payload) % 4)

        decoded = base64.urlsafe_b64decode(payload)

        return json.loads(decoded)

    except Exception as e:
        print(f"\nERROR: {e}")
        return None


def _normalize_groups(groups):
    if isinstance(groups, str):
        return [g.strip() for g in groups.split(",") if g.strip()]
    if isinstance(groups, list):
        return groups
    return []


def lambda_handler(event, context):
    event = event or {}
    auth_header = event.get("authorization", "")
    token = event.get("token") or auth_header.replace("Bearer ", "")

    if not token:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Missing token"}),
        }

    decoded = decode_jwt(token)
    if not decoded:
        return {
            "statusCode": 401,
            "body": json.dumps({"message": "Invalid token"}),
        }

    groups = _normalize_groups(decoded.get("cognito:groups", []))
    matched_token_id = mark_token_used(decoded, getattr(context, "aws_request_id", None))
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "username": decoded.get("username", "NOT FOUND"),
                "email": decoded.get("email", "NOT FOUND"),
                "groups": groups,
                "token_tracking_id": matched_token_id,
            }
        ),
    }

# ==================================================
# MAIN
# ==================================================

def main():
    token = input("Paste Access Token:\n\n").strip()
    decoded = decode_jwt(token)

    if decoded:
        print("\n===================================")
        print("TOKEN CLAIMS")
        print("===================================\n")
        print(json.dumps(decoded, indent=4))

        print("\n===================================")
        print("IDENTITY SUMMARY")
        print("===================================\n")

        username = decoded.get("username", "NOT FOUND")
        email = decoded.get("email", "NOT FOUND")

        print(f"Username : {username}")
        print(f"Email    : {email}")

        groups = _normalize_groups(decoded.get("cognito:groups", []))

        print("\n===================================")
        print("GROUP MEMBERSHIP")
        print("===================================\n")

        if groups:
            for group in groups:
                print(f" - {group}")
        else:
            print("No Cognito groups found")
            print("\nPossible Causes:")
            print(" - User not assigned to group")
            print(" - Wrong token type")
            print(" - Authentication before group assignment")

        print("\n===================================")


if __name__ == "__main__":
    main()