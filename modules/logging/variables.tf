variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure Log Analytics Workspace resource names."
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'test', 'stage', 'prod')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Log Analytics Workspace will be created."
}

variable "location" {
  type        = string
  description = "The Azure region where the Log Analytics Workspace will be deployed (e.g., 'eastus', 'westeurope')."
}

variable "name" {
  type        = string
  description = "The base name for the Log Analytics Workspace resource."
}

variable "log_analytics_workspace" {
  type        = any
  description = "A configuration object defining Log Analytics Workspace properties (e.g., SKU, retention period, daily quota)."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value tags to apply to the Log Analytics Workspace for governance, cost tracking, and organization."
  default     = {}
}
