output "id" {
  description = "A map of the full resource IDs of the created managed identities, keyed by application name."
  value       = azurerm_user_assigned_identity.main.id
}

output "principal_id" {
  description = "A map of the Principal IDs of the created managed identities, keyed by application name."
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  description = "A map of the Client IDs of the created managed identities, keyed by application name."
  value       = azurerm_user_assigned_identity.main.client_id
}