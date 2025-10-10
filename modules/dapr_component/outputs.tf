output "id" {
  description = "The ID of the created Dapr component."
  value       = azurerm_container_app_environment_dapr_component.this.id
}

output "name" {
  description = "The name of the Dapr component."
  value       = azurerm_container_app_environment_dapr_component.this.name
}

output "type" {
  description = "The type of the Dapr component."
  value       = azurerm_container_app_environment_dapr_component.this.component_type
}

output "scopes" {
  description = "The scopes configured for this Dapr component."
  value       = var.scopes
}