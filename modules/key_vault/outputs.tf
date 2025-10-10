output "id" {
  description = "A map of the full resource IDs of the created Key Vaults, keyed by application name."
  value       = azurerm_key_vault.main.id
  depends_on  = [azurerm_role_assignment.terraform_sp_access]
}

output "name" {
  description = "A map of the names of the created Key Vaults, keyed by application name."
  value       = azurerm_key_vault.main.name
}

output "uri" {
  description = "A map of the URIs of the created Key Vaults, keyed by application name."
  value       = azurerm_key_vault.main.vault_uri
}