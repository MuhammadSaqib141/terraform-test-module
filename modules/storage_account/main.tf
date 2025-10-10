resource "azurerm_storage_account" "main" {
  name                     = substr(replace("${var.org_prefix}${var.environment}${var.name}", "-", ""), 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_config.account_tier
  account_replication_type = var.storage_config.account_replication_type
  account_kind             = var.storage_config.account_kind

  min_tls_version                 = try(var.storage_config.min_tls_version, "TLS1_2")
  https_traffic_only_enabled      = try(var.storage_config.https_traffic_only_enabled, true)
  allow_nested_items_to_be_public = try(var.storage_config.allow_nested_items_to_be_public, false)

  tags = var.tags

  dynamic "blob_properties" {
    for_each = var.storage_config.blob_properties != null ? [var.storage_config.blob_properties] : []
    content {
      versioning_enabled       = try(blob_properties.value.versioning_enabled, false)
      change_feed_enabled      = try(blob_properties.value.change_feed_enabled, false)
      last_access_time_enabled = try(blob_properties.value.last_access_time_enabled, false)

      dynamic "delete_retention_policy" {
        for_each = try(blob_properties.value.delete_retention_policy, null) != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }
    }
  }
}