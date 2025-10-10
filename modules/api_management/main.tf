resource "azurerm_api_management" "main" {

  name                = "${var.org_prefix}-${var.environment}-${var.name}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  publisher_name  = var.api_management_service.publisher_name
  publisher_email = var.api_management_service.publisher_email
  sku_name        = var.api_management_service.sku_name

  identity {
    type         = var.api_management_service.system_assigned_identity == true ? "SystemAssigned" : (length(var.user_assigned_identity_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : "None")
    identity_ids = var.user_assigned_identity_resource_ids
  }

  virtual_network_type = var.api_management_service.virtual_network_subnet_id != null ? "Internal" : "None"
  dynamic "virtual_network_configuration" {
    for_each = var.api_management_service.virtual_network_subnet_id != null ? [1] : []
    content {
      subnet_id = var.api_management_service.virtual_network_subnet_id
    }
  }

  security {
    enable_backend_ssl30  = false
    enable_backend_tls10  = false
    enable_backend_tls11  = false
    enable_frontend_ssl30 = false
    enable_frontend_tls10 = false
    enable_frontend_tls11 = false
  }
}
