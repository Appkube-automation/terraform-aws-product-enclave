provider "aws" {
  region = var.region  
}

module "vpc" {
  source     = "git::https://github.com/tmknom/terraform-aws-vpc.git?ref=tags/2.0.1"
  #cidr_block = "10.255.0.0/16"
  cidr_block = var.vpc_cidr
  name       = var.vpc_name

  #public_subnet_cidr_blocks  = ["10.255.0.0/24", "10.255.1.0/24","10.255.2.0/24"]
  #public_availability_zones  = ["us-east-1a", "us-east-1c","us-east-1e"]
  #private_subnet_cidr_blocks = ["10.255.64.0/24", "10.255.65.0/24", "10.255.66.0/24"]
  #private_availability_zones = ["us-east-1a", "us-east-1c","us-east-1e"]

  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  public_availability_zones  = var.public_availability_zones
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  private_availability_zones = var.private_availability_zones

  instance_tenancy        = "default"
  enable_dns_support      = false
  enable_dns_hostnames    = false
  map_public_ip_on_launch = false

  enabled_nat_gateway        = true
  enabled_single_nat_gateway = true

  #uncomment the following lines to enable flow logs for the VPC
  #we need to provide an s3 bucket name to log storage
  
  # enable_flow_log           = true
  # flow_log_destination_type = "s3"
  # flow_log_destination_arn  = var.log_bucket_name

  tags = {
    Environment = "eks_cluster_vpc"
  }
}

resource "aws_lb" "eks_cluster_lb" {
  internal           = false
  load_balancer_type = var.load_balancer_type  
  subnets            = module.vpc.public_subnet_ids
  tags = {
    Environment = "eks_cluster_lb"
  }
}

# resource "aws_wafv2_regex_pattern_set" "example" {
#   name        = "example"
#   description = "Example regex pattern set"
#   scope       = "REGIONAL"

#   regular_expression {
#     regex_string = "one"
#   }

#   regular_expression {
#     regex_string = "two"
#   }

#   tags = {
#     Environment = "dev"
#   }
# }

# resource "aws_wafv2_ip_set" "example" {
#   name               = "devipset"
#   description        = "Dev IP set"
#   scope              = "REGIONAL"
#   ip_address_version = "IPV4"
#   addresses          = ["1.2.3.4/32", "5.6.7.8/32"]

#   tags = {
#     Environment = "dev"
#   }
# }

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

resource "aws_wafv2_regex_pattern_set" "common" {
  name  = "Common"
  scope = "REGIONAL"

  regular_expression {
    regex_string = "^.*(some-url).*((.domain)+)\\.com$"
  }

  #  Add here additional regular expressions for other endpoints, they are merging with OR operator, e.g.

  /*
   regular_expression {
      regex_string = "^.*(jenkins).*((.domain)+)\\.com$"
   }
   */

  tags = {
    Environment = "dev"
  }
}

resource "aws_wafv2_web_acl" "dev_acl" {
  name        = "devacl-managed"
  description = "alb and apigateway protect."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 10

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
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
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

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # rule {
  #   name     = "AWS-AWSManagedRulesLinuxRuleSet"
  #   priority = 2

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesLinuxRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   override_action {
  #     none {}
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # rule {
  #   name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
  #   priority = 3

  #   override_action {
  #     none {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesKnownBadInputsRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # rule {
  #   name     = "PreventHostInjections"
  #   priority = 0

  #   statement {
  #     regex_pattern_set_reference_statement {
  #       arn = aws_wafv2_regex_pattern_set.common.arn

  #       field_to_match {
  #         single_header {
  #           name = "host"
  #         }
  #       }

  #       text_transformation {
  #         priority = 0
  #         type     = "NONE"
  #       }
  #     }
  #   }

  #   action {
  #     allow {}
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "PreventHostInjections"
  #     sampled_requests_enabled   = true
  #   }
  # }

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

# API gateway

resource "aws_lambda_function" "myLambda" {
   function_name = "firstFunction"

   
   s3_bucket = "acc-request"
   s3_key    = "hello.zip"

   
   handler = "hello.handler"
   runtime = "nodejs12.x"

   role = aws_iam_role.lambda_role.arn
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "lambda_role" {
   name = "role_lambda"

   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = "myAPI"
}



resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxyMethod.resource_id
   http_method = aws_api_gateway_method.proxyMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.myLambda.invoke_arn
}


resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.myLambda.invoke_arn
}


resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.myLambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "setdeploy" {
  rest_api_id = aws_api_gateway_rest_api.apiLambda.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxyMethod.id,
      aws_api_gateway_integration.lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "setstage" {
  deployment_id = aws_api_gateway_deployment.apideploy.id
  rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
  stage_name    = "setstage"
}

resource "aws_wafv2_web_acl_association" "apitowaf" {
  resource_arn = aws_api_gateway_stage.setstage.arn
  web_acl_arn  = aws_wafv2_web_acl.dev_acl.arn
}

resource "aws_wafv2_web_acl_association" "lbtowaf" {
  resource_arn = aws_lb.eks_cluster_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.dev_acl.arn
}

# output "base_url" {
#   value = aws_api_gateway_deployment.apideploy.invoke_url
# }