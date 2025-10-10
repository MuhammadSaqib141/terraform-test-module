data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  # 'ot' is an abbreviation for 'ordertracking'.
  name = substr(
    trim(
      replace(lower("ot-${var.environment}-${var.name}-kv"), "_", "-"),
      "-"
    ),
    0,
    24
  )

  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags

  sku_name                      = var.key_vault.sku_name
  soft_delete_retention_days    = var.key_vault.soft_delete_retention_days
  purge_protection_enabled      = var.key_vault.purge_protection_enabled
  enable_rbac_authorization     = var.key_vault.enable_rbac_authorization
  public_network_access_enabled = var.key_vault.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.key_vault.network_acls != null ? [var.key_vault.network_acls] : []
    content {
      bypass         = network_acls.value.bypass
      default_action = network_acls.value.default_action
      ip_rules       = try(network_acls.value.ip_rules, [])
    }
  }
}
