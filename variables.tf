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
variable "region" {
  type = string
  default = "us-east-1"
}
variable "vpc_name" {
  type = string
  default = "eks_cluster_vpc"
}
variable "vpc_cidr" {
      description = "Kubernetes cluster CIDR notation for vpc."
      #validation {
       # condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}($|/(16))$"))
        #error_message = "Vpc_cidr invalid?"
      type        = string
      default     = "10.255.0.0/16"

      }

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default     = [
    "10.255.0.0/24",
    "10.255.1.0/24",
    "10.255.2.0/24",
  ]
}
variable "public_availability_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = [
    "us-east-1a",
    "us-east-1c",
    "us-east-1e",
  ]
}
variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets."
  type        = list(string)
  default     = [
    "10.255.64.0/24",
    "10.255.65.0/24",
    "10.255.66.0/24"
  ]
}
variable "private_availability_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = [
    "us-east-1a",
    "us-east-1c",
    "us-east-1e",
  ]
}
variable "load_balancer_type" {
  type = string
  default = "application"
}