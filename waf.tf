/* ######################################################################################################################
# This file defines AWS WAFv2 Web ACLs for CloudFront distributions. 
# It includes a basic Web ACL with the AWS Managed Rules Common Rule Set and an additional Web ACL with the AWS Managed Rules ATP Rule Set for advanced threat protection. 
# The Web ACLs are scoped to CloudFront and have default allow actions, with specific rules to count requests that match the ATP rule set.
# Visibility configurations are included for monitoring and logging purposes.
#
# NOTE:
# If you use the aws_wafv2_web_acl_rule or aws_wafv2_web_acl_rule_group_association resources with this Web ACL, you must add lifecycle { ignore_changes = [rule] } to this resource to prevent configuration drift. 
# Those resources manage the Web ACL's rules outside of this resource's direct management.
# This would be done if using multiple repos or external resources to manage the Web ACL rules, such as for a shared WAF across multiple applications or teams.
###############################################################################################################*/

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl

resource "aws_wafv2_web_acl" "taaops_cf_waf01" {
  provider = aws.us-west-2

  name  = "${var.project_name}-cf-waf01"
  scope = "REGIONAL"
  # scope = "CLOUDFRONT" # Use this scope for CloudFront distributions. 
  # Note that CloudFront WAFv2 Web ACLs must be created in the us-east-1 region.

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    # Enable CloudWatch metrics and sampled request logging for this rule to monitor its activity and effectiveness.
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule to block or count requests from IPs that exceed the configured limit in a 5-minute window.
  # This helps mitigate abusive traffic patterns.
  rule {
    name     = "RateLimitRule"
    priority = 2

    dynamic "action" {
      for_each = [var.waf_rate_limit_action]
      content {
        dynamic "block" {
          for_each = action.value == "block" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = action.value == "count" ? [1] : []
          content {}
        }
      }
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limit
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-cf-waf-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cf-waf01"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "python_api_waf_assoc" {
  count    = var.enable_waf ? 1 : 0
  provider = aws.us-west-2

  resource_arn = aws_api_gateway_stage.PythonStage.arn
  web_acl_arn  = aws_wafv2_web_acl.taaops_cf_waf01.arn
}

resource "aws_wafv2_web_acl_association" "node_api_waf_assoc" {
  count    = var.enable_waf ? 1 : 0
  provider = aws.us-west-2

  resource_arn = aws_api_gateway_stage.NodeStage.arn
  web_acl_arn  = aws_wafv2_web_acl.taaops_cf_waf01.arn
}


/* ######################################################################################################################
# Account Takeover Protection (ATP) Web ACL for CloudFront
resource "aws_wafv2_web_acl" "taaops_atp_cf_waf01" {
  provider    = aws.us-west-2
  name        = "${var.project_name}-atp-cf-waf01"
  description = "Managed ATP rule."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "atp-rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesATPRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_atp_rule_set {
            login_path = "/api/1/signin"

            request_inspection {
              password_field {
                identifier = "/password"
              }

              payload_type = "JSON"

              username_field {
                identifier = "/email"
              }
            }

            response_inspection {
              status_code {
                failure_codes = ["403"]
                success_codes = ["200"]
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "atp-rule-metric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "atp-waf-metric"
    sampled_requests_enabled   = false
  }
}
*/