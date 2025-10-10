output "account_id" {
  description = "The resource ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.id
}
output "account_name" { value = azurerm_cosmosdb_account.main.name }
output "database_name" { value = azurerm_cosmosdb_sql_database.main.name }
output "container_name" { value = azurerm_cosmosdb_sql_container.main.name }
output "primary_key" {
  description = "The primary key for the Cosmos DB account."
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "endpoint" {
  description = "The endpoint for the Cosmos DB account."
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "connection_string" {
  value     = azurerm_cosmosdb_account.main.primary_sql_connection_string
  sensitive = true
}
