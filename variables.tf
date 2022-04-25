variable "web_acl_name" {
  type = string
  default = "testtfACL"
}
variable "web_acl_metics" {
  type = string
  default = "aclmetrics"
}
variable "waf_rule_name" {
  type = string
  default = "test-rule-1"
}
variable "waf_rule_metrics" {
  type = string
  default = "testrulemetrics"
}
variable "waf_rule_group_name" {
  type = string
  default = "test-waf-rule-group"
}
variable "waf_rule_group_metrics" {
  type = string
  default = "testgroupmetrics"
}