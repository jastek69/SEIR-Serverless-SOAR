# Cognito User Pool
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool
#
# RBAC flow:
# 1. User authenticates with Cognito.
# 2. Cognito issues an access token with scopes like rbac-api/admin or rbac-api/user.
# 3. API Gateway validates the token and checks authorization_scopes.
# 4. Lambda optionally checks cognito:groups for Layer 2 application RBAC.

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server

resource "aws_cognito_resource_server" "rbac_api_resource_server" {
  identifier = "rbac-api"
  name       = "RBAC REST API"

  scope {
    scope_name        = "admin"
    scope_description = "Admin access to protected RBAC API methods"
  }

  scope {
    scope_name        = "user"
    scope_description = "User access to protected RBAC API methods"
  }

  user_pool_id = aws_cognito_user_pool.cognito_rbac_pool.id
}


resource "aws_cognito_user_pool" "cognito_rbac_pool" {
  name = "rbac-user-pool"

  mfa_configuration        = "ON"
  auto_verified_attributes = ["email"]

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length    = 12
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
}

resource "aws_cognito_user_pool_client" "cognito_rbac_pool_client" {
  name                                 = "rbac-app-client"
  user_pool_id                         = aws_cognito_user_pool.cognito_rbac_pool.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
    "${aws_cognito_resource_server.rbac_api_resource_server.identifier}/admin",
    "${aws_cognito_resource_server.rbac_api_resource_server.identifier}/user"
  ]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  callback_urls = ["https://localhost/callback"] # Required for OAuth flows, even if not used in this example
  logout_urls   = ["https://localhost/logout"]   # Required for OAuth flows, even if not used in this example

  supported_identity_providers = ["COGNITO"]
}

# M2M (client_credentials) app client — for headless/automated callers that
# can't do the browser-based Authorization Code + PKCE flow above (e.g. the
# stability_ai GPU workstation submitting comfyui_gen jobs to POST /jobs).
# No user involved -> no MFA, no cognito:groups claim at all; submit_job.py
# maps a token with no groups but the rbac-api/user scope to the "m2m"
# pseudo-group, which group_entitlements already treats like any other
# group. Reuses the SAME resource server/scope as the human client above —
# no separate scope needed for machine callers today.
#
# Same pattern docs/MCP.md already anticipated for future M2M callers
# (e.g. the not-yet-built ml-tools MCP server) — this client and its SSM
# paths are shared infrastructure, not stability_ai-specific, so a second
# M2M consumer later doesn't need its own client.
resource "aws_cognito_user_pool_client" "m2m_client" {
  name                                 = "rbac-m2m-client"
  user_pool_id                         = aws_cognito_user_pool.cognito_rbac_pool.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes = [
    "${aws_cognito_resource_server.rbac_api_resource_server.identifier}/user"
  ]

  # client_credentials is pure server-to-server token issuance — no
  # redirect involved, so no callback/logout URLs needed (unlike the code
  # grant above, which requires them even when unused).

  # Default access-token validity is 1h; an unattended workstation
  # shouldn't have to re-mint that often.
  access_token_validity = 8
  token_validity_units {
    access_token = "hours"
  }

  supported_identity_providers = ["COGNITO"]
}

# Published so any M2M caller (this account, this repo's Cognito pool) can
# mint tokens without a hardcoded/copy-pasted secret. Client ID is not
# sensitive on its own; the secret is SecureString. Whatever IAM role
# actually calls ssm:GetParameter here (e.g. stability_ai's own Lambda/EC2
# role, defined in that repo) needs a policy statement granting
# ssm:GetParameter + kms:Decrypt on these two parameter ARNs — that grant
# lives in the CONSUMING repo, not here, same as any other cross-project
# IAM policy reference.
resource "aws_ssm_parameter" "m2m_client_id" {
  name        = "/mcp/auth/m2m-client-id"
  description = "Cognito M2M app client ID (rbac-m2m-client) — client_credentials grant, rbac-api/user scope"
  type        = "String"
  value       = aws_cognito_user_pool_client.m2m_client.id
}

resource "aws_ssm_parameter" "m2m_client_secret" {
  name        = "/mcp/auth/m2m-client-secret"
  description = "Cognito M2M app client secret (rbac-m2m-client) — never in code or committed files, read this at call time"
  type        = "SecureString"
  value       = aws_cognito_user_pool_client.m2m_client.client_secret
}

output "m2m_token_endpoint" {
  description = "POST here with grant_type=client_credentials (HTTP Basic client_id:secret) to mint an M2M access token"
  value       = "https://${aws_cognito_user_pool_domain.cognito_rbac_pool_domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
}

# Domain for the Cognito User Pool, required for OAuth flows. This can be a Cognito hosted domain or a custom domain if you have a Route53 zone.

resource "aws_cognito_user_pool_domain" "cognito_rbac_pool_domain" {
  domain       = "rbac-user-pool-domain" # Change this to a unique domain prefix https://your-domain-prefix.auth.us-west-2.amazoncognito.com
  user_pool_id = aws_cognito_user_pool.cognito_rbac_pool.id
}


# Adding groups which were being handled manually as part of the runbook
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.cognito_rbac_pool.id
  description  = "Administrators with privileged RBAC access"
  precedence   = 1
}

resource "aws_cognito_user_group" "user" {
  name         = "user"
  user_pool_id = aws_cognito_user_pool.cognito_rbac_pool.id
  description  = "Standard users with non-admin RBAC access"
  precedence   = 2
}


### MCP INTEGRATION HERE ###