resource "azurerm_eventhub_namespace" "main" {
  name                          = "${var.org_prefix}-${var.environment}-${replace(var.name, "_", "-")}-ehns"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.config.sku
  capacity                      = try(var.config.capacity, null)
  auto_inflate_enabled          = try(var.config.auto_inflate_enabled, null)
  maximum_throughput_units      = try(var.config.maximum_throughput_units, null)
  minimum_tls_version           = try(var.config.minimum_tls_version, "1.2")
  local_authentication_enabled  = try(var.config.local_authentication_enabled, true)
  public_network_access_enabled = try(var.config.public_network_access_enabled, true)
  dedicated_cluster_id          = try(var.config.dedicated_cluster_id, null)
  tags                          = var.tags

  dynamic "network_rulesets" {
    for_each = var.config.network_rules_enabled ? [1] : []
    content {
      default_action                 = var.config.network_rules_default_action
      public_network_access_enabled  = try(var.config.public_network_access_enabled, true)
      trusted_service_access_enabled = var.config.network_trusted_service_access_enabled

      dynamic "ip_rule" {
        for_each = var.config.allowed_cidrs
        content {
          ip_mask = ip_rule.value
          action  = "Allow"
        }
      }

      dynamic "virtual_network_rule" {
        for_each = var.config.allowed_subnet_ids
        content {
          subnet_id = virtual_network_rule.value
        }
      }
    }
  }
}


resource "azurerm_eventhub" "main" {
  name                = var.config.hub_name
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = var.config.partition_count
  message_retention   = var.config.message_retention
  status              = try(var.config.status, "Active")
}

# ADD: Entity-specific authorization rule
resource "azurerm_eventhub_authorization_rule" "hub_specific" {
  name                = "${var.config.hub_name}-rule"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = var.resource_group_name

  # Minimum required permissions for Dapr
  listen = true  # Required for consuming messages
  send   = true  # Required for publishing messages
  manage = false # Not needed for Dapr runtime
}

# Consumer group for the application
resource "azurerm_eventhub_consumer_group" "main" {
  name                = var.config.consumer_group_name != null ? var.config.consumer_group_name : "${var.name}-consumers"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = var.resource_group_name
  user_metadata       = try(var.config.consumer_group_metadata, null)
}

# Storage container for checkpointing (if checkpoint storage is provided)
resource "azurerm_storage_container" "checkpoints" {
  count                 = var.config.checkpoint_storage_account_name != null ? 1 : 0
  name                  = "${replace(var.name, "_", "-")}-checkpoints"
  storage_account_name  = var.config.checkpoint_storage_account_name
  container_access_type = "private"
}