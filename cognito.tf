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
