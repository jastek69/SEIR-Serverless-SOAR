# Jobs table — PK job_id; GSI status-index (status + updated_at) drives both
# the status API's list-by-state queries and the stuck-job detector's
# "running jobs with stale heartbeats" sweep. TTL on expires_at keeps the
# table from accumulating dead records.
#
# GSI uses key_schema blocks (provider 6.x style) — that's what the
# hash_key/range_key deprecation warnings were about. The table-level
# hash_key stays: this provider version (~>6.42) has no table-level
# key_schema (confirmed against the provider schema), and validate is
# warning-free with this shape.

resource "aws_dynamodb_table" "jobs" {
  name         = "${local.name_prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"

  attribute {
    name = "job_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "updated_at"
    type = "N"
  }

  global_secondary_index {
    name            = "status-index"
    projection_type = "ALL"

    key_schema {
      attribute_name = "status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "updated_at"
      key_type       = "RANGE"
    }
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-table"
  })
}
