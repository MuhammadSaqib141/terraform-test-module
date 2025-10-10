output "id" { value = azurerm_container_app.main.id }
output "name" { value = azurerm_container_app.main.name }
output "fqdn" { value = try(azurerm_container_app.main.ingress[0].fqdn, null) }
output "identity_principal_id" { value = azurerm_container_app.main.identity[0].principal_id }