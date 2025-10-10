output "id" { value = azurerm_search_service.this.id }
output "name" { value = azurerm_search_service.this.name }
output "endpoint" {
  value = "https://${azurerm_search_service.this.name}.search.windows.net"
}
output "primary_key" {
  value     = azurerm_search_service.this.primary_key
  sensitive = true
}
output "query_keys" {
  value     = azurerm_search_service.this.query_keys
  sensitive = true
}
output "identity_principal_id" { value = azurerm_search_service.this.identity[0].principal_id }
