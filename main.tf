provider "aws" {
  region = "us-east-1"  
}

module "vpc" {
  source     = "git::https://github.com/tmknom/terraform-aws-vpc.git?ref=tags/2.0.1"
  cidr_block = "10.255.0.0/16"
  name       = "eks_cluster_vpc"

  public_subnet_cidr_blocks  = ["10.255.0.0/24", "10.255.1.0/24","10.255.2.0/24"]
  public_availability_zones  = ["us-east-1a", "us-east-1c","us-east-1e"]
  private_subnet_cidr_blocks = ["10.255.64.0/24", "10.255.65.0/24", "10.255.66.0/24"]
  private_availability_zones = ["us-east-1a", "us-east-1c","us-east-1e"]

  instance_tenancy        = "default"
  enable_dns_support      = false
  enable_dns_hostnames    = false
  map_public_ip_on_launch = false

  enabled_nat_gateway        = true
  enabled_single_nat_gateway = true

  tags = {
    Environment = "eks_cluster_vpc"
  }
}

resource "aws_lb" "eks_cluster_lb" {
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  tags = {
    Environment = "eks_cluster_lb"
  }
}

resource "aws_wafv2_regex_pattern_set" "example" {
  name        = "example"
  description = "Example regex pattern set"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "one"
  }

  regular_expression {
    regex_string = "two"
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_wafv2_ip_set" "example" {
  name               = "devipset"
  description        = "Dev IP set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["1.2.3.4/32", "5.6.7.8/32"]

  tags = {
    Environment = "dev"
  }
}

# resource "aws_wafv2_rule_group" "dev_rule_group" {
#   name     = "dev-rule"
#   scope    = "REGIONAL"
#   capacity = 2

#   rule {
#     name     = "rule-1"
#     priority = 1

#     action {
#       allow {}
#     }

#     statement {

#       geo_match_statement {
#         country_codes = ["US", "NL"]
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = false
#       metric_name                = "dev-rule-metric-name"
#       sampled_requests_enabled   = false
#     }
#   }
# }

resource "aws_wafv2_web_acl" "dev_acl" {
  name        = "devacl-managed"
  description = "alb and apigateway protect."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "dev-rule-metric"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Environment = "dev"
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "devacl-metric"
    sampled_requests_enabled   = false
  }
}



# WAF Rules

# Creating the IP Set tp be defined in AWS WAF 
 
# resource "aws_waf_ipset" "ipset" {
#    name = "MyFirstipset"
#    ip_set_descriptors {
#      type = "IPV4"
#      value = "10.111.0.0/20"
#    }
# }
 
# # Creating the AWS WAF rule that will be applied on AWS Web ACL
 
# resource "aws_waf_rule" "waf_rule" { 
#   depends_on = [aws_waf_ipset.ipset]
#   name        = var.waf_rule_name
#   metric_name = var.waf_rule_metrics
#   predicates {
#     data_id = aws_waf_ipset.ipset.id
#     negated = false
#     type    = "IPMatch"
#   }
# }
 
# # Creating the Rule Group which will be applied on  AWS Web ACL
 
# resource "aws_waf_rule_group" "rule_group" {  
#   name        = var.waf_rule_group_name
#   metric_name = var.waf_rule_metrics
 
#   activated_rule {
#     action {
#       type = "COUNT"
#     }
#     priority = 50
#     rule_id  = aws_waf_rule.waf_rule.id
#   }
# }
 
# # Creating the Web ACL component in AWS WAF
 
# resource "aws_waf_web_acl" "waf_acl" {
#   depends_on = [ 
#      aws_waf_rule.waf_rule,
#      aws_waf_ipset.ipset,
#       ]
#   name        = var.web_acl_name
#   metric_name = var.web_acl_metics
 
#   default_action {
#     type = "ALLOW"
#   }
#   rules {
#     action {
#       type = "BLOCK"
#     }
#     priority = 1
#     rule_id  = aws_waf_rule.waf_rule.id
#     type     = "REGULAR"
#  }
# }