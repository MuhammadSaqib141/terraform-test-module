resource "azurerm_monitor_action_group" "main" {
  for_each = var.action_groups

  name                = each.key
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "main" {
  for_each = var.log_alert_rules

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  description    = each.value.description
  enabled        = each.value.enabled
  data_source_id = var.log_analytics_workspace_id
  query          = each.value.query
  severity       = each.value.severity
  frequency      = each.value.frequency
  time_window    = each.value.time_window

  trigger {
    operator  = each.value.operator
    threshold = each.value.threshold
  }

  action {
    action_group = [lookup(azurerm_monitor_action_group.main, each.value.action_group_key, null).id]
  }
}