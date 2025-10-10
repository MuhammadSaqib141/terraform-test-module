resource "azurerm_container_app_environment_dapr_component" "this" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  component_type               = var.type
  version                      = var.dapr_version
  scopes                       = length(var.scopes) > 0 ? var.scopes : null

  # Process metadata items
  dynamic "metadata" {
    for_each = var.metadata
    content {
      name = metadata.value.name

      # Use value if present, otherwise null
      value = try(metadata.value.value, null)

      # Use secretName if secretName is present in the metadata object
      secret_name = try(metadata.value.secretName, null)
    }
  }

  # Process secrets (if any)
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  # Note: As of current provider version, tags might not be supported on Dapr components
  # Uncomment if your provider version supports it:
  # tags = var.tags
}