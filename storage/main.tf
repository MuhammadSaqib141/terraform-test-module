resource "azurerm_storage_account" "storage" {
  name                     = "mystorageaccount123"
  resource_group_name      = "my-resource-group"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
