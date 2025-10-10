variable "name" {
  type        = string
  description = "The base name of the resource or service being deployed. Used to construct resource names consistently."
}

variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, applied to Azure resource names for standardization."
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'test', 'stage', 'prod')."
}

variable "location" {
  type        = string
  description = "The Azure region where the resource(s) will be deployed (e.g., 'eastus', 'westeurope')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the resource(s) will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to apply to the resource(s) for cost tracking, governance, and organization."
  default     = {}
}

variable "config" {
  type        = any
  description = "A configuration object containing resource-specific settings for this module (e.g., SKU, scaling, networking, or identity options)."
}
