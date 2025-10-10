resource "azurerm_container_app_environment" "main" {

  name                = "${var.org_prefix}-${var.environment}-${replace(var.name, "_", "-")}-cae"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs_destination           = var.container_app_environment.logs_destination

  # infrastructure_subnet_id =var.container_app_environment.subnet_id  #var.container_app_environment.infrastructure_subnet_id
  infrastructure_subnet_id = try(var.container_app_environment.subnet_id, null)
  zone_redundancy_enabled  = try(var.container_app_environment.subnet_id, null) != null ? var.container_app_environment.zone_redundancy_enabled : null
  # zone_redundancy_enabled  = var.container_app_environment.subnet_id != null ? var.container_app_environment.zone_redundancy_enabled : null

}
