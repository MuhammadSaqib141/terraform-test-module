output "id" {
  description = "A map of the full resource IDs of the created Container App Environments, keyed by application name."
  value       = azurerm_container_app_environment.main.id
}

output "name" {
  description = "A map of the names of the created Container App Environments, keyed by application name."
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "A map of the default domain names for the created Container App Environments, keyed by application name."
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip" {
  description = "A map of the static outbound IP addresses for the created Container App Environments, keyed by application name."
  value       = azurerm_container_app_environment.main.static_ip_address
}