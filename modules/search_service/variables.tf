variable "org_prefix" { type = string }
variable "environment" { type = string }
variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "search_config" {
  type = any
}
