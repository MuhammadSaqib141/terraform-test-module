variable "diagnostics" {
  description = "Map of diagnostic settings to apply."
  type = map(object({
    target_resource_id             = string
    log_analytics_workspace_id     = string
    log_categories                 = list(string)
    metric_categories              = list(string)
    log_analytics_destination_type = optional(string, "AzureDiagnostics")
  }))
}
/*
variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Log Analytics Workspace will be created."
}

variable "log_analytics_workspace" {
  type        = any
  description = "A configuration object defining Log Analytics Workspace properties (e.g., SKU, retention period, daily quota)."
}

variable "location" {
  type        = string
  description = "The Azure region where the Log Analytics Workspace will be deployed (e.g., 'eastus', 'westeurope')."
}
*/