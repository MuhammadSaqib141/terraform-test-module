variable "org_prefix" {
  type        = string
  description = "The prefix for all resources (e.g., 'ordertracking')."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g., 'dev')."
}

variable "location" {
  type        = string
  description = "The Azure region where the identities will be created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the identities will be deployed."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the identities."
  default     = {}
}

variable "name" {
  type        = string
  description = "A map of managed identity configuration objects to create."
}