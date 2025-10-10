resource "azurerm_user_assigned_identity" "main" {
  # name                = "${var.org_prefix}-${var.environment}-${var.name}-id"
  name                = "${var.org_prefix}-${var.environment}-${replace(var.name, "_", "-")}-id"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}