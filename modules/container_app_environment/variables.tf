variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure resource names (e.g., 'ordertracking')."
}

variable "environment" {
  type        = string
  description = "The target deployment environment, such as 'dev', 'test', 'stage', or 'prod'."
}

variable "location" {
  type        = string
  description = "The Azure region where the Container App Environment (CAE) resources will be created (e.g., 'eastus', 'westeurope')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Container App Environment will be deployed."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to assign to the Container App Environment and related resources for cost tracking, governance, and organization."
  default     = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the shared Log Analytics Workspace to which Container App Environment diagnostics and logs will be sent."
}

variable "container_app_environment" {
  type        = any
  description = "A configuration block defining one or more Container App Environments (CAE). This is typically passed as a dynamically constructed map from the root module."
  default     = {}
}

variable "name" {
  type        = string
  description = "The base name for the Container App Environment. Used to construct resource names consistently."
}
