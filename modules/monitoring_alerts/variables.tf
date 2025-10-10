# ./modules/monitoring_alerts/variables.tf

variable "location" {
  type        = string
  description = "Azure region for the alert resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to deploy alerts into (typically the 'infra' RG)."
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all monitoring resources."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics Workspace to query against."
}

variable "action_groups" {
  description = "A map of action groups to create."
  type = map(object({
    short_name = string
    email_receivers = list(object({
      name          = string
      email_address = string
    }))
    # You can add webhook_receivers, sms_receivers etc. here
  }))
  default = {}
}

variable "log_alert_rules" {
  description = "A map of scheduled query alert rules to create."
  type = map(object({
    description      = optional(string, "Log-based alert rule")
    enabled          = optional(bool, true)
    query            = string
    severity         = number
    frequency        = number # in minutes
    time_window      = number # in minutes
    threshold        = number
    operator         = string # "GreaterThan", "LessThan", "Equal"
    action_group_key = string # Key of the action group to link from the 'action_groups' variable
  }))
  default = {}
}