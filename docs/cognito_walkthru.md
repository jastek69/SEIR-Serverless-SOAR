Cognito ClickOps Lab — User Authentication (No Federation)
We will do Federation in SEIR-II

Objective---> “We are not building a login page. We are building an identity system that issues tokens.”

Students will:

    Create a User Pool
    Enable login with:
        username
        email
        phone number
    Enforce MFA
    Create and authenticate a user
    Use the JWT to call your REST API

Updated Flow: Client → WAF → API Gateway (Cognito Authorizer) → Lambda


Task 1 — Create Cognito User Pool
  Navigation
  
    AWS Console → Cognito
    Click User Pools
    Click Create user pool


Step-by-Step Configuration


1. Sign-in Options

Select: “We allow multiple identity inputs. Real systems don’t force one.”

        ✔ Username
        ✔ Email
        ✔ Phone number

2. Password Policy

Keep default or slightly stronger:

        Min 8 characters
        Numbers + symbols

3. MFA Configuration---> “MFA is not optional in real systems.”

Set: Required MFA

        MFA Types:
        ✔ SMS
        ✔ TOTP (Authenticator app)

4. User Account Recovery

        Enable:
        ✔ Email
        ✔ Phone

5. Attributes

Set required:

        ✔ email
        ✔ phone_number

6. App Client

Create one:

Name: chewbacca-client

Disable: ----> ❌ Client secret

Why? Client secret complicates API usage. We keep it simple.

Click Create

Task 2 — Create a User

Inside User Pool:

        Go to Users
        Click Create user

Fill:

        Username: lizzo1
        Email: student1@lizzo.com
        Phone: +1XXXXXXXXXX

Set password manually: --->  Permanent password
“We are skipping email verification to move faster. We will return to it later"

Task 3 — Enable MFA for User

Inside User:
        Click user
        Set MFA:

        ✔ Enable MFA
        ✔ Choose:

SMS OR Authenticator app

If TOTP:
    Scan QR code with:
        Google Authenticator
        or Microsoft Authenticator


Task 4 — Get JWT Token (CLI Method)
This isn't easy. Let's go slow.

Use AWS CLI:

        aws cognito-idp initiate-auth \
          --auth-flow USER_PASSWORD_AUTH \
          --client-id <CLIENT_ID> \
          --auth-parameters USERNAME=student1,PASSWORD=YourPassword

If MFA is required → challenge returned

Then run:

        aws cognito-idp respond-to-auth-challenge \
          --client-id <CLIENT_ID> \
          --challenge-name SMS_MFA \
          --challenge-responses USERNAME=student1,SMS_MFA_CODE=123456 \
          --session <SESSION>

Result:

You get:

        {
          "AuthenticationResult": {
            "IdToken": "...",
            "AccessToken": "...",
            "RefreshToken": "..."
          }
        }

Use: AccessToken

Task 5 — Create API Gateway Authorizer

Go to API Gateway (REST API)--> Authorizers → Create New ---> Type: Cognito ---> 

Configure:

        Name:chewbacca-authorizer
        Cognito User Pool: → Select your pool
        Token Source: Authorization

Task 6 — Attach Authorizer to Methods

For /python and For /node:

    Method Request --> Authorization: Cognito Authorizer
 
Task 7 — Deploy API (Again!)

👉 REST API requires redeploy
Actions → Deploy API → prod

Task 8 — Test

Without Token ---> 

        curl https://<api>/prod/python 

 --> 401 Unauthorized
 

With Token -->  

        curl https://<api>/prod/python \
          -H "Authorization: <ACCESS_TOKEN>" 

→ 200 OK


Task 9 — Verify Behavior

1. Did Lambda run when no token?
2. Where was request blocked?
3. What changed in event?

Final Explanation

    What Cognito does?
    What API Gateway does?
    What MFA adds?
    Why AccessToken matters?



[initiate-auth](https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/initiate-auth.html)
    -auth-parameters (map)

--auth-parameters (map)

The authentication parameters. These are inputs corresponding to the AuthFlow that you’re invoking.

The following are some authentication flows and their parameters. Add a SECRET_HASH parameter if your app client has a client secret. Add DEVICE_KEY if you want to bypass multi-factor authentication with a remembered device.

USER_AUTH
USERNAME (required)

PREFERRED_CHALLENGE . If you don’t provide a value for PREFERRED_CHALLENGE , Amazon Cognito responds with the AvailableChallenges parameter that specifies the available sign-in methods.

USER_SRP_AUTH

USERNAME (required)

SRP_A (required)

USER_PASSWORD_AUTH

USERNAME (required)

PASSWORD (required)

REFRESH_TOKEN_AUTH/REFRESH_TOKEN

REFRESH_TOKEN (required)

CUSTOM_AUTH

USERNAME (required)

ChallengeName: SRP_A (when doing SRP authentication before custom challenges)

SRP_A: (An SRP_A value) (when doing SRP authentication before custom challenges)

For more information about SECRET_HASH , see Computing secret hash values . For information about DEVICE_KEY , see Working with user devices in your user pool .

key -> (string)

Constraints:

min: 0
max: 131072
value -> (string)

Constraints:

min: 0
max: 131072
Shorthand Syntax:

KeyName1=string,KeyName2=string
JSON Syntax:

{"string": "string"
  ...}
--client-metadata (map)

A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers.

When Amazon Cognito invokes any of these functions, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute that provides the data that you assigned to the ClientMetadata parameter in your request. In your function code, you can process the clientMetadata value to enhance your workflow for your specific needs.

To review the Lambda trigger types that Amazon Cognito invokes at runtime with API requests, see Connecting API actions to Lambda triggers in the Amazon Cognito Developer Guide .

The ClientMetadata value is passed as input to the functions for only the following triggers:

Pre signup
Pre authentication
User migration
This request also invokes the functions for the following triggers, but doesn’t pass ClientMetadata :

Post authentication
Custom message
Pre token generation
Create auth challenge
Define auth challenge
Custom email sender
Custom SMS sender
Note
When you use the ClientMetadata parameter, note that Amazon Cognito won’t do the following:

Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn’t include triggers, the ClientMetadata parameter serves no purpose.
Validate the ClientMetadata value.
Encrypt the ClientMetadata value. Don’t send sensitive information in this parameter.
key -> (string)

Constraints:

min: 0
max: 131072
value -> (string)

Constraints:

min: 0
max: 131072
Shorthand Syntax:

KeyName1=string,KeyName2=string
JSON Syntax:

{"string": "string"
  ...}
--client-id (string) [required]

The ID of the app client that your user wants to sign in to.

Constraints:

min: 1
max: 128
pattern: [\w+]+
--analytics-metadata (structure)


To sign in a user

The following initiate-auth example signs in a user with the basic username-password flow and no additional challenges.

aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id 1example23456789 \
    --analytics-metadata AnalyticsEndpointId=d70b2ba36a8c4dc5a04a0451aEXAMPLE \
    --auth-parameters USERNAME=testuser,PASSWORD=[Password] --user-context-data EncodedData=mycontextdata --client-metadata MyTestKey=MyTestValue
Output:

{
    "AuthenticationResult": {
        "AccessToken": "eyJra456defEXAMPLE",
        "ExpiresIn": 3600,
        "TokenType": "Bearer",
        "RefreshToken": "eyJra123abcEXAMPLE",
        "IdToken": "eyJra789ghiEXAMPLE",
        "NewDeviceMetadata": {
            "DeviceKey": "us-west-2_a1b2c3d4-5678-90ab-cdef-EXAMPLE11111",
            "DeviceGroupKey": "-v7w9UcY6"
        }
    }
}
For more information, see Authentication in the Amazon Cognito Developer Guide.