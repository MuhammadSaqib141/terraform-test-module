output "workspace_id" {
  description = "A map of the full resource IDs of the created Log Analytics Workspaces."
  value       = azurerm_log_analytics_workspace.main.id
}
output "workspace_name" {
  description = "A map of the names of the created Log Analytics Workspaces."
  value       = azurerm_log_analytics_workspace.main.name
}