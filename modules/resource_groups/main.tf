resource "azurerm_resource_group" "main" {
  name     = "${var.org_prefix}-${var.environment}-${var.name}-rg"
  location = var.location
  tags     = var.tags
}