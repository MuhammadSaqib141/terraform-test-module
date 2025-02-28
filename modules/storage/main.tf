# -------------------- Storage Account --------------------
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  min_tls_version          = "TLS1_2"
}

# -------------------- Blob Containers --------------------
resource "azurerm_storage_container" "blob_containers" {
  for_each              = toset(var.blob_containers)
  name                  = each.key
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# -------------------- File Shares --------------------
resource "azurerm_storage_share" "file_shares" {
  for_each             = toset(var.file_shares)
  name                 = each.key
  storage_account_name = azurerm_storage_account.storage.name
  quota               = 5  # Quota in GB (modify as needed)
}

