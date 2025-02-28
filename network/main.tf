resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  location            = "East US"
  resource_group_name = "my-resource-group"
  address_space       = ["10.0.0.0/16"]
}
