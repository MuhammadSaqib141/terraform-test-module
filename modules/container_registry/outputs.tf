output "registry_id" {
  description = "A map of the full resource IDs of the created Container Registries."
  value       = azurerm_container_registry.main.id
}

output "registry_name" {
  description = "A map of the names of the created Container Registries."
  value       = azurerm_container_registry.main.name
}

output "registry_login_server" {
  description = "A map of the login server URLs of the created Container Registries."
  value       = azurerm_container_registry.main.login_server
}