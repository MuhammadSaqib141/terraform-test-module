resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.org_prefix}-${var.environment}-${var.name}-log"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku                             = var.log_analytics_workspace.sku
  retention_in_days               = var.log_analytics_workspace.retention_in_days
  daily_quota_gb                  = var.log_analytics_workspace.daily_quota_gb
  allow_resource_only_permissions = var.log_analytics_workspace.allow_resource_only_permissions
  local_authentication_disabled   = var.log_analytics_workspace.local_authentication_disabled
  cmk_for_query_forced            = var.log_analytics_workspace.cmk_for_query_forced
  internet_ingestion_enabled      = var.log_analytics_workspace.internet_ingestion_enabled
  internet_query_enabled          = var.log_analytics_workspace.internet_query_enabled
  data_collection_rule_id         = var.log_analytics_workspace.data_collection_rule_id

  reservation_capacity_in_gb_per_day = var.log_analytics_workspace.sku == "CapacityReservation" ? var.log_analytics_workspace.reservation_capacity_in_gb_per_day : null
}