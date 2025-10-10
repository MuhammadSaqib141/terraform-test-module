resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostics

  name                           = "${each.key}-diag"
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type != null ? each.value.log_analytics_destination_type : "AzureDiagnostics"

  # Logs
  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "enabled_metric" {
    for_each = each.value.metric_categories
    content {
      category = enabled_metric.value
    }
  }

}

/*
resource "azurerm_monitor_scheduled_query_rules_alert" "apim_high_error_rate" {
  name                = "apim-high-error-rate"
  resource_group_name = var.resource_group_name
  location            = var.location

  data_source_id = var.log_analytics_workspace 
  
  query = <<-QUERY
  ApiManagementGatewayLogs
  | summarize 
      TotalRequests = count(),
      FailedRequests = countif(ResponseCode >= 400)
  | extend ErrorRate = (toreal(FailedRequests) * 100.0 / TotalRequests)
  | where ErrorRate > 5
  QUERY

  frequency   = 5    # Check every 5 minutes
  time_window = 15   # Over a 15-minute window

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group = [azurerm_monitor_action_group.alerts.id]
  }

  severity = 2
}


resource "azurerm_monitor_scheduled_query_rules_alert" "eventhub_throttled" {
  name                = "eventhub-throttled-requests"
  resource_group_name = var.resource_group_name
  location            = var.location

  data_source_id = var.log_analytics_workspace
  
  query = <<-QUERY
  AzureDiagnostics
  | where ResourceProvider == "MICROSOFT.EVENTHUB"
  | where ResultSignature == "429"
  | summarize ThrottledRequests = count() by Resource
  QUERY

  frequency   = 5
  time_window = 15

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group = [azurerm_monitor_action_group.alerts.id]
  }

  severity = 3
}

*/

# resource "azurerm_monitor_scheduled_query_rules_alert" "job_errors" {
#   name                = "job-errors-detected"
#   resource_group_name = var.resource_group_name
#   location            = var.location

#   data_source_id = var.log_analytics_workspace

#   query = <<-QUERY
#   search "*"
#   | where Level == "Error" or SeverityLevel == "Error" or ResultType == "Failed"
#   | where OperationName contains "Job" or OperationName contains "Runbook"
#   QUERY

#   frequency   = 5
#   time_window = 15

#   trigger {
#     operator  = "GreaterThan"
#     threshold = 0
#   }

#   action {
#     action_group = [azurerm_monitor_action_group.alerts.id]
#   }

#   severity = 1
# }

/*
resource "azurerm_monitor_action_group" "alerts" {
  name                = "critical-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "critalert"

  email_receiver {
    name          = "muhammad-saqib"
    email_address = "admin@example.com"
  }
}
*/