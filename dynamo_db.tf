# DynamoDB schema for secure token lifecycle handling.
#
# Table 1: token-tracking
# - Purpose: token/session lifecycle metadata
# - Primary key: token_id (S)
# - GSIs:
#   - user-expiry-index (username + expires_at)
#   - status-expiry-index (status + expires_at)
#   - token-hash-index (token_hash)
#
# Table 2: token-revocation
# - Purpose: fast denylist lookup for revoked tokens
# - Primary key: token_hash (S)
# - TTL: expires_at (epoch seconds)
################################################


# data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# Table 1: token tracking metadata
resource "aws_dynamodb_table" "dynamoDb_token_tracking" {
  name         = "token-tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_id"

  attribute {
    name = "token_id"
    type = "S"
  }

  attribute {
    name = "token_hash"
    type = "S"
  }

  attribute {
    name = "username"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "expires_at"
    type = "N"
  }

  global_secondary_index {
    name            = "user-expiry-index"
    
    key_schema {
      attribute_name = "username"
      key_type = "HASH"
    }
    
    key_schema {
      attribute_name = "expires_at"
      key_type = "RANGE"
    }

    
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-expiry-index"
    
    key_schema {
      attribute_name = "status"
      key_type = "HASH"
    }


    key_schema {
      attribute_name = "expires_at"
      key_type = "RANGE"
    }
    
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "token-hash-index"
    
    key_schema {
      attribute_name = "token_hash"
      key_type = "HASH"
    }

    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name      = "token-tracking"
    Component = "auth"
  }
}

# Table 2: revocation denylist
resource "aws_dynamodb_table" "dynamoDb_token_revocation" {
  name         = "token-revocation"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_hash"

  attribute {
    name = "token_hash"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name      = "token-revocation"
    Component = "auth"
  }
}

