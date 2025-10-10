resource "azurerm_container_registry" "main" {
  name                = "${replace(var.org_prefix, "-", "")}${var.environment}${replace(var.name, "_", "")}acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku                           = var.container_registry.sku
  admin_enabled                 = coalesce(var.container_registry.admin_enabled, false)
  public_network_access_enabled = coalesce(var.container_registry.public_network_access_enabled, true)
  network_rule_bypass_option    = coalesce(var.container_registry.network_rule_bypass_option, "AzureServices")

  # dynamic "network_rule_set" {
  #   for_each = var.container_registry.sku == "Premium" ? [1] : []

  #   content {
  #     default_action = "Deny"

  #      # CI/CD Agent IP
  #     # dynamic "ip_rule" {
  #     #   for_each = var.container_registry.agent_public_ip != null ? [var.container_registry.agent_public_ip] : []
  #     #   content {
  #     #     action   = "Allow"
  #     #     ip_range = ip_rule.value
  #     #   }
  #     # }

  #     dynamic "network_rule_set" {
  #       for_each = var.container_registry.public_network_access_enabled == false ? [1] : []
  #       content {
  #         default_action = "Deny"
  #       }
  #     }
  #   }
  #   }

  dynamic "network_rule_set" {
    for_each = var.container_registry.public_network_access_enabled == false ? [1] : []
    content {
      default_action = "Deny"
    }
  }

  dynamic "georeplications" {
    for_each = try(var.container_registry.georeplications, [])
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }
}