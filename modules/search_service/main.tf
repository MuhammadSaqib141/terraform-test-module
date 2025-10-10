resource "azurerm_search_service" "this" {
  name                = substr(replace("${var.org_prefix}${var.environment}${var.name}search", "-", ""), 0, 60)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.search_config.sku

  # Partition/Replica settings
  partition_count = var.search_config.sku == "free" || var.search_config.sku == "basic" ? null : var.search_config.partition_count
  replica_count   = var.search_config.replica_count

  # Security
  public_network_access_enabled = var.search_config.public_network_access_enabled
  local_authentication_enabled  = try(var.search_config.local_authentication_enabled, true)

  # Optional fields
  allowed_ips                              = try(var.search_config.allowed_ips, null)
  authentication_failure_mode              = try(var.search_config.authentication_failure_mode, null)
  customer_managed_key_enforcement_enabled = try(var.search_config.customer_managed_key_enforcement_enabled, false)
  hosting_mode                             = try(var.search_config.hosting_mode, "default")
  network_rule_bypass_option               = try(var.search_config.network_rule_bypass_option, "None")
  semantic_search_sku                      = try(var.search_config.semantic_search_sku, null)

  # Identity block
  dynamic "identity" {
    for_each = var.search_config.identity == null ? [] : [var.search_config.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  tags = var.tags
}
