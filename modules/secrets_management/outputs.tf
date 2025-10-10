output "secrets" {
  description = "A map of all the created Key Vault secret resources, keyed by the unique name provided in the input variable. Allows accessing individual secret properties like '.id' and '.version'."
  value       = azurerm_key_vault_secret.secrets
  sensitive   = true
}