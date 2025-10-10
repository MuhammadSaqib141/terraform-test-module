resource "azurerm_container_app" "main" {
  name = substr(
    replace(
      "${var.org_prefix}-${var.environment}-${var.name}-ca",
      "_", "-"
    ),
    0, 32
  )
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  dapr {
    app_id       = var.name
    app_port     = var.container_app.ingress.enabled ? var.container_app.ingress.target_port : 5000
    app_protocol = "http"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }


  # dynamic "registry" {
  #   # Agar image ka naam 'mcr.microsoft.com' se shuru NAHI ho raha, to yeh block create karo.
  #   for_each = !can(regex("^mcr\\.microsoft\\.com", var.container_app.image_name)) ? [1] : []

  #   content {
  #     server   = var.registry_server
  #     identity = var.user_assigned_identity_id
  #   }
  # }

  registry {
    server   = var.registry_server
    identity = var.user_assigned_identity_id
  }

  # ---------------------------

  template {
    container {
      name = substr(
        replace(
          "${var.org_prefix}-${var.environment}-${var.name}-c",
          "_", "-"
        ),
        0, 32
      )
      # image = can(regex("\\.", var.container_app.image_name)) ? "${var.container_app.image_name}:${var.container_app.image_tag}" : "${var.registry_server}/${var.container_app.image_name}:${var.container_app.image_tag}"
      image  = can(regex("\\.", var.container_app.image_name)) ? "${var.container_app.image_name}:${var.container_app.image_tag}" : "${var.registry_server}/${var.container_app.image_name}:${var.container_app.image_tag}"
      cpu    = var.container_app.cpu
      memory = var.container_app.memory
    }
    min_replicas = var.container_app.min_replicas
    max_replicas = var.container_app.max_replicas
  }


  dynamic "ingress" {
    for_each = var.container_app.ingress.enabled ? [1] : []
    content {
      external_enabled = true
      target_port      = var.container_app.ingress.target_port
      transport        = "auto"

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

}