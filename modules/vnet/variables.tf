variable "org_prefix" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "name" { type = string }

variable "vnet_config" {
  description = "The entire configuration object for a single virtual network, including subnets and NSGs."
  type        = any
}