output "vnet_id" {
  description = "The ID of the virtual network."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "A map of subnet names to their resource IDs."
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}