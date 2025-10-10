output "ids" {
  value = { for k, v in azurerm_cdn_frontdoor_profile.main : k => v.id }
}
output "endpoint_hostnames" {
  value = { for k, v in azurerm_cdn_frontdoor_endpoint.main : k => v.host_name }
}