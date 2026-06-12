JWT Authentication — API Gateway

“Right now, your API is public. Anyone on the internet can hit it. JWT adds identity to every request.”

🎯 Objective: Protect your API so that:

    Only requests with a valid JWT token are allowed
    Unauthorized requests are rejected (401)
    Lambda is only executed if authentication passes

🔑 What is JWT (simple + operator framing)

A JWT is:

    A signed token
    Contains identity (user, claims)
    Verified by API Gateway before Lambda runs

🔁 New Request Flow: Client → API Gateway (JWT Check) → Lambda → Logs

👉 Important Limitation: If JWT fails → Lambda is NEVER called

🧱 Task Flow Overview

We will:

    Create a JWT issuer (Auth0) (fastest for lab)
    Configure JWT Authorizer in API Gateway
    Attach authorizer to routes
    Test with and without token

⚙️ Task 1 — Create JWT Issuer (Auth0)

Use: Auth0

Steps:
    Go to Auth0 dashboard
    Create Application
    Type: Machine to Machine

Capture These Values (CRITICAL)

From Auth0:

  Domain: https://your-tenant.auth0.com/
  Audience: https://my-api

Important Note: “These are your trust anchors. API Gateway will verify tokens using this.”

Bullet Summary
1. Create a Python script to generate the Cognito `SECRET_HASH`
2. Generate the `SECRET_HASH` by running the python script
3. Call `initiate-auth` to start authentication. This initiates an authorization request and returns a session when MFA is required.
4. Call `respond-to-auth-challenge` to respond to the MFA session challenge.
5. Retrieve JWTs from `AuthenticationResult`.
NOTE: Respond to the MFA challenge immediately because the `Session` value expires quickly.



# Cognito JWT Flow Summary:
reference links:
https://repost.aws/knowledge-center/cognito-unable-to-verify-secret-hash
https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html

1. Create a Python script to generate the Cognito `SECRET_HASH`

2. Generate the `SECRET_HASH` by running the python script using: `python <appname.py> <username> <client id> <client secret>`
    * example: `python auth.py ziontheo 7im6sn4tj742m8s7njfr7olqga ri6fb0nihm6p3p05k36g32318o74olvh695ht7455o64728g8t5`
	* Cognito username
	* Cognito app client ID
	* Cognito app client secret value

3. Call `initiate-auth` to start authentication. This initiates an authorization request and returns a session when MFA is required.

Inputs:
- `USERNAME`
- `PASSWORD`
- `SECRET_HASH`

Output with MFA enabled:
- `ChallengeName`
- `Session`

4. Call `respond-to-auth-challenge` to respond to the MFA session challenge.

Inputs:
- `USERNAME`
- `SOFTWARE_TOKEN_MFA_CODE`
- `SECRET_HASH`
- `Session` from `initiate-auth`

NOTE: the challenge name is `SOFTWARE_TOKEN_MFA`.

Output:
- `AuthenticationResult`

Example:
```
set +H
MFA_CODE='123456'
SESSION='PASTE_SESSION_VALUE_HERE'

aws cognito-idp respond-to-auth-challenge \
  --region us-east-1 \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --challenge-name SOFTWARE_TOKEN_MFA \
  --session "$SESSION" \
  --challenge-responses "USERNAME=ziontheo,SOFTWARE_TOKEN_MFA_CODE=$MFA_CODE,SECRET_HASH=$SECRET_HASH" \
  --output json
```

5. Retrieve JWTs from `AuthenticationResult`.
NOTE: Respond to the MFA challenge immediately because the `Session` value expires quickly.

Output returns tokens:
1. `AccessToken`
2. `RefreshToken`
3. `IdToken`



NOTE on Passwords: ! in a password
In Bash ! can mean “expand something from command history.” 
 set +H should be run before commands that include !. 

Solutions: 
Run `set +H` first, then store the password in a single-quoted variable. The single quotes protect the password assignment, and `set +H` protects later commands from Bash history expansion.

Step 1: use `set +H` which tells Bash to treat ! as a normal character and not a history shortcut

Step 2: Use single ' ' and set password as VAR PASSWORD

Example:
```
set +H

PASSWORD='Armag3dd0n!69'
SECRET_HASH='NnewiFWnsu52sBfNCuSdTW/VyyjBIpJB9UepJwV40sY='

aws cognito-idp initiate-auth \
  --region us-east-1 \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --auth-parameters "USERNAME=ziontheo,PASSWORD=$PASSWORD,SECRET_HASH=$SECRET_HASH" \
  --output json
```


# TEAR DOWN
Delete the Cognito user pool in AWS Cognito console.
 
IMPORTANT: Charges may apply for Cognito usage




# Cognito JWT - In Depth instructions:

1. Create a Python script to generate the Cognito `SECRET_HASH`
[verify secret hash](https://repost.aws/knowledge-center/cognito-unable-to-verify-secret-hash)

auth.py
``` python
import sys, hmac, hashlib, base64

# Unpack command line arguments
username, app_client_id, key = sys.argv[1:4]

# Create message and key bytes
message, key = (username + app_client_id).encode('utf-8'), key.encode('utf-8')

# Calculate secret hash
secret_hash = base64.b64encode(hmac.new(key, message, digestmod=hashlib.sha256).digest()).decode()

print(f"Secret Hash for user '{username}': {secret_hash}")
```


2. Generate the `SECRET_HASH` by running the python script using: `python <appname.py> <username> <client id> <client secret>`
    * example: `python auth.py ziontheo 7im6sn4tj742m8s7njfr7olqga ri6fb0nihm6p3p05k36g32318o74olvh695ht7455o64728g8t5`
	* Cognito username
	* Cognito app client ID
	* Cognito app client secret value

Notes: Replace username with the username of the user that's in the user pool. Also, replace app_client_id with your user pool's app client ID and key with your app client's secret

To get the secret hash value, run the following command:
`python3 secret_hash.py username app_client_id app_client_secret`

3. Call `initiate-auth` to start authentication. This initiates an authorization request and returns a session when MFA is required.
[AWS CLI Command Reference - initiate-auth](https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html)
Inputs:
- `USERNAME`
- `PASSWORD`
- `SECRET_HASH`

Output with MFA enabled:
- `ChallengeName`
- `Session`

```
set +H
SECRET_HASH='NnewiFWnsu52sBfNCuSdTW/VyyjBIpJB9UepJwV40sY='

aws cognito-idp initiate-auth \
  --region us-east-1 \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --auth-parameters "USERNAME=ziontheo,PASSWORD=Armag3dd0n!69,SECRET_HASH=$SECRET_HASH" \
  --output json
```

4. Copy the new "Session" value, then immediately call: `respond-to-auth-challenge` to respond to the MFA session challenge.
NOTE: with MFA you will have to obtain the MFA Token from Authenticator App for the `SOFTWARE_TOKEN_MFA_CODE` so have the app ready

Inputs:
- `USERNAME`
- `SOFTWARE_TOKEN_MFA_CODE`
- `SECRET_HASH`
- `Session` from `initiate-auth`

NOTE: the challenge name is `SOFTWARE_TOKEN_MFA`.

Output:
- `AuthenticationResult`

Example:
```
set +H
MFA_CODE='123456'
SESSION='PASTE_SESSION_VALUE_HERE'

aws cognito-idp respond-to-auth-challenge \
  --region us-east-1 \
  --client-id '7im6sn4tj742m8s7njfr7olqga' \
  --challenge-name SOFTWARE_TOKEN_MFA \
  --session "$SESSION" \
  --challenge-responses "USERNAME=ziontheo,SOFTWARE_TOKEN_MFA_CODE=$MFA_CODE,SECRET_HASH=$SECRET_HASH" \
  --output json
```

5. Retrieve JWTs from `AuthenticationResult`.
NOTE: Respond to the MFA challenge immediately because the `Session` value expires quickly.

Output returns tokens:
- `AuthenticationResult`
    1. `AccessToken`
    2. `RefreshToken`
    3. `IdToken`
