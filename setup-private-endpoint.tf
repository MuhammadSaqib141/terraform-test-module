# =================================================================================
# PRIVATE NETWORKING FOR PREMIUM ACR
# This file contains all resources required to set up a private endpoint for any
# Azure Container Registry configured with sku = "Premium" and
# public_network_access_enabled = false.
# =================================================================================

# ---------------------------------------------------------------------------------
# 1. DERIVED LOCALS FOR PRIVATE NETWORKING
# ---------------------------------------------------------------------------------
locals {
  private_container_registries = {
    for k, v in var.container_registries : k => v
    if try(v.sku, "") == "Premium" && try(v.public_network_access_enabled, true) == false
  }

  private_networking_enabled = length(local.private_container_registries) > 0
}

# ---------------------------------------------------------------------------------
# 2. AGENT VNET DATA SOURCE
# ---------------------------------------------------------------------------------
data "azurerm_virtual_network" "agent_vnet" {
  count = local.private_networking_enabled ? 1 : 0

  name                = "ismaeel-vnet"
  resource_group_name = var.agent_rg_name
}

# ---------------------------------------------------------------------------------
# 3. PRIVATE DNS ZONE
# ---------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "acr" {
  count = local.private_networking_enabled ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
}

# ---------------------------------------------------------------------------------
# 4. PRIVATE ENDPOINTS (using for_each)
# ---------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "acr" {
  for_each = local.private_container_registries

  name                = "${module.container_registries[each.key].registry_name}-pe"
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  location            = var.location
  subnet_id           = module.vnet["main"].subnet_ids["pe-subnet"]
  tags                = local.tags

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }

  private_service_connection {
    name                           = "${module.container_registries[each.key].registry_name}-psc"
    private_connection_resource_id = module.container_registries[each.key].registry_id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  depends_on = [module.vnet, module.container_registries]
}

# ---------------------------------------------------------------------------------
# 5. VNET PEERING & DNS LINKS
# ---------------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "acr_app_link" {
  count = local.private_networking_enabled ? 1 : 0

  name                  = "${var.org_prefix}-${var.environment}-acr-dns-app-link"
  resource_group_name   = module.resource_groups[var.resource_group_infra].name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = module.vnet["main"].vnet_id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_agent_link" {
  count = local.private_networking_enabled ? 1 : 0

  name                  = "${var.org_prefix}-${var.environment}-acr-dns-agent-link"
  resource_group_name   = module.resource_groups[var.resource_group_infra].name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = data.azurerm_virtual_network.agent_vnet[0].id
  registration_enabled  = true
}

resource "azurerm_virtual_network_peering" "app_to_agent" {
  count = local.private_networking_enabled ? 1 : 0

  name                      = "peering-app-to-agent"
  resource_group_name       = module.resource_groups[var.resource_group_infra].name
  virtual_network_name      = module.vnet["main"].vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.agent_vnet[0].id
}

resource "azurerm_virtual_network_peering" "agent_to_app" {
  count = local.private_networking_enabled ? 1 : 0

  name                      = "peering-agent-to-app"
  resource_group_name       = data.azurerm_virtual_network.agent_vnet[0].resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.agent_vnet[0].name
  remote_virtual_network_id = module.vnet["main"].vnet_id
}

# ---------------------------------------------------------------------------------
# 6. PROPAGATION DELAY
# ---------------------------------------------------------------------------------
resource "time_sleep" "wait_for_dns_propagation" {
  count = local.private_networking_enabled ? 1 : 0

  create_duration = "120s"

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.acr_app_link,
    azurerm_private_dns_zone_virtual_network_link.acr_agent_link
  ]
}