resource "azurerm_virtual_network" "main" {
  name                = "${var.org_prefix}-${var.environment}-${var.name}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  address_space       = var.vnet_config.address_space
}

resource "azurerm_subnet" "main" {
  for_each = var.vnet_config.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_security_group" "main" {
  for_each = {
    for sn_key, sn_value in var.vnet_config.subnets : sn_key => sn_value
    if try(sn_value.network_security_group, null) != null
  }

  name                = "${var.org_prefix}-${var.environment}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.network_security_group.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = {
    for sn_key, sn_value in var.vnet_config.subnets : sn_key => sn_value
    if try(sn_value.network_security_group, null) != null
  }

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}