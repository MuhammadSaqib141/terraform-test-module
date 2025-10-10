# FILE: ./modules/event_hub/outputs.tf
output "namespace_name" {
  value = azurerm_eventhub_namespace.main.name
}

output "namespace_id" {
  value = azurerm_eventhub_namespace.main.id

}

output "hub_name" {
  value = azurerm_eventhub.main.name
}

output "namespace_connection_string" {
  description = "DEPRECATED: Use hub_connection_string instead"
  value       = azurerm_eventhub_namespace.main.default_primary_connection_string
  sensitive   = true
}

# RECOMMENDED: Hub-specific connection string
output "hub_connection_string" {
  description = "Entity-specific connection string for the Event Hub"
  value       = azurerm_eventhub_authorization_rule.hub_specific.primary_connection_string
  sensitive   = true
}

output "hub_connection_string_listen_only" {
  description = "Listen-only connection string (for workers that only consume)"
  value       = azurerm_eventhub_authorization_rule.hub_specific.primary_connection_string
  sensitive   = true
}

output "consumer_group_name" {
  value = azurerm_eventhub_consumer_group.main.name
}

output "checkpoint_container_name" {
  value = try(azurerm_storage_container.checkpoints[0].name, null)
}