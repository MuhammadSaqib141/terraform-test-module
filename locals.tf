locals {
  # Core tags
  tags = merge(
    var.common_tags,
    {
      app         = var.org_prefix
      environment = var.environment
      managed_by  = "OpenTofu"
    }
  )

  # ============================================================================
  # CONTAINER APP ANALYSIS
  # ============================================================================

  # Flatten and categorize container apps
  all_container_apps = merge([
    for app_name, app in var.applications : {
      for ca_name, ca in app.container_apps :
      "${app_name}-${ca_name}" => {
        app_name = app_name
        ca_name  = ca_name
        config   = ca
      }
    }
  ]...)

  # Categorize apps by type for each application
  app_components = {
    for app_name, app in var.applications : app_name => {
      workers = [for name, config in app.container_apps : name if !config.ingress.enabled]
      apis    = [for name, config in app.container_apps : name if config.ingress.enabled]
      all     = keys(app.container_apps)
    }
  }

  # ============================================================================
  # INFRASTRUCTURE REFERENCES
  # ============================================================================

  # Consolidated infrastructure references per application
  app_infrastructure = {
    for app_name, app in var.applications : app_name => {
      # Key Vault
      keyvault_name = try(module.application_key_vaults[app_name].name, "")

      # Storage for Event Hub Checkpoints
      storage_account_name = module.checkpoint_storage.name
      # storage_container_name = "${app_name}-checkpoints"
      storage_container_name = "${replace(app_name, "_", "-")}-checkpoints"
      # Consumer Group Name
      consumer_group_name = "${replace(app_name, "_", "-")}-consumers"
      # Cosmos DB
      cosmos_url        = try(module.application_cosmos_dbs[app_name].endpoint, "")
      cosmos_database   = try(app.cosmos_db.database_name, "ordersdb")
      cosmos_collection = try(app.cosmos_db.container_name, "orders")

      # Event Hub
      eventhub_namespace  = try(module.application_event_hubs[app_name].namespace_name, "")
      eventhub_connection = try(module.application_event_hubs[app_name].hub_connection_string, "")

      # Container App Environment
      cae_id = module.application_cae[app_name].id
    }
  }


  # ============================================================================
  # DAPR COMPONENT DISCOVERY
  # ============================================================================

  # Discover all template files
  dapr_templates = merge(
    # Shared components
    {
      for file in fileset("${path.module}/dapr/components/shared", "*.yaml.tftpl") :
      "shared-${trimsuffix(file, ".yaml.tftpl")}" => {
        template_path  = "${path.module}/dapr/components/shared/${file}"
        component_type = trimsuffix(file, ".yaml.tftpl")
        target_app     = keys(var.applications)[0] # Shared uses first app
        is_shared      = true
      }
    },
    # Application-specific components
    merge([
      for app_name in keys(var.applications) : {
        for file in try(fileset("${path.module}/dapr/components/${app_name}", "*.yaml.tftpl"), []) :
        "${app_name}-${trimsuffix(file, ".yaml.tftpl")}" => {
          template_path  = "${path.module}/dapr/components/${app_name}/${file}"
          component_type = trimsuffix(file, ".yaml.tftpl")
          target_app     = app_name
          is_shared      = false
        }
      }
    ]...)
  )

  component_scopes = {
    for key, template in local.dapr_templates : key =>
    (template.component_type == "pubsub" && try(var.applications[template.target_app].event_hub, null) != null) ?
    local.app_components[template.target_app].all :

    (template.component_type == "statestore" && try(var.applications[template.target_app].cosmos_db, null) != null) ?
    local.app_components[template.target_app].workers :

    template.component_type == "secretstore" ? [] : []
  }

  # ============================================================================
  # TEMPLATE VARIABLES
  # ============================================================================

  # Build template variables for each component
  template_vars = {
    for key, template in local.dapr_templates : key => merge(
      local.app_infrastructure[template.target_app],
      {
        scopes = local.component_scopes[key]
      }
    )
  }

  # ============================================================================
  # DAPR COMPONENT RENDERING
  # ============================================================================

  # Render Dapr components from templates
  dapr_components = {
    for key, template in local.dapr_templates : key => {
      # Component metadata
      name     = trimsuffix(basename(template.template_path), ".yaml.tftpl")
      type     = template.component_type
      app_name = template.target_app

      # Render template
      rendered_yaml = templatefile(
        template.template_path,
        local.template_vars[key]
      )

      # Parse rendered YAML
      parsed = yamldecode(
        templatefile(
          template.template_path,
          local.template_vars[key]
        )
      )
    }
  }

  # ============================================================================
  # SECRET MAPPINGS
  # ============================================================================

  # Map secrets to components
  component_secrets = {
    for key, comp in local.dapr_components : key =>
    comp.type == "pubsub" ? {
      "eventhub-connection-string"       = local.app_infrastructure[comp.app_name].eventhub_connection
      "eventhub-checkpoints-storage-key" = module.checkpoint_storage.primary_access_key
    } :
    comp.type == "statestore" ? {
      "cosmosdb-master-key" = try(module.application_cosmos_dbs[comp.app_name].primary_key, "")
    } : {}
  }



  application_secrets = merge(
    # Event Hub connection strings
    {
      for app_name, app in var.applications :
      "${app_name}-eventhub-connection" => {
        name         = "eventhub-connection-string"
        value        = module.application_event_hubs[app_name].hub_connection_string
        key_vault_id = module.application_key_vaults[app_name].id
        content_type = "Azure Event Hub Connection String"
      } if app.event_hub != null
    },

    # Cosmos DB keys
    {
      for app_name, app in var.applications :
      "${app_name}-cosmos-key" => {
        name         = "cosmosdb-master-key"
        value        = module.application_cosmos_dbs[app_name].primary_key
        key_vault_id = module.application_key_vaults[app_name].id
        content_type = "Azure Cosmos DB Primary Key"
      } if app.cosmos_db != null
    },

    # Storage account keys for checkpointing
    {
      for app_name, app in var.applications :
      "${app_name}-storage-key" => {
        name         = "eventhub-checkpoints-storage-key"
        value        = module.checkpoint_storage.primary_access_key
        key_vault_id = module.application_key_vaults[app_name].id
        content_type = "Azure Storage Account Key"
      } if app.event_hub != null
    },
    # AI Search Admin Keys
    {
      for app_name, secret_names in local.app_search_secret_names :
      "${app_name}-ai-search-admin-key" => {
        name         = secret_names.admin_key_name
        value        = module.search_service.primary_key
        key_vault_id = module.application_key_vaults[app_name].id
        content_type = "AI Search Admin Key"
      }
    },
    # AI Search Query Keys
    {
      for app_name, secret_names in local.app_search_secret_names :
      "${app_name}-ai-search-query-key" => {
        name         = secret_names.query_key_name
        value        = module.search_service.query_keys[0].key
        key_vault_id = module.application_key_vaults[app_name].id
        content_type = "AI Search Query Key"
      }
    }
  )

  # Naming convention for application-specific search secrets and named values
  app_search_secret_names = {
    for app_name, app_config in var.applications :
    app_name => {
      admin_key_name = "${replace(app_name, "_", "-")}-ai-search-admin-key"
      query_key_name = "${replace(app_name, "_", "-")}-ai-search-query-key"
    }
    if try(app_config.search_setup, null) != null
  }

  # ----------------------------
  # Static resources (single per env)
  # ----------------------------
  shared_diagnostics = {
    acr = {
      target_resource_id = module.container_registries["main"].registry_id
      log_categories     = ["ContainerRegistryLoginEvents", "ContainerRegistryRepositoryEvents"]
    }
    search = {
      target_resource_id = module.search_service.id
      log_categories     = ["OperationLogs"]
    }
    apim = {
      target_resource_id             = module.api_management["main"].id
      log_categories                 = ["GatewayLogs"]
      log_analytics_destination_type = "Dedicated"
    }
    front_door = {
      target_resource_id = module.front_door.ids["main"]
      log_categories     = ["FrontdoorAccessLog", "FrontdoorHealthProbeLog", "FrontdoorWebApplicationFirewallLog"]
    }
  }

  # ----------------------------
  # Dynamic per-application resources
  # ----------------------------
  application_diagnostics = merge(

    # Cosmos DB
    {
      for app_name, app in var.applications :
      "${app_name}-cosmos" => {
        target_resource_id = try(module.application_cosmos_dbs[app_name].account_id, null)
        log_categories     = ["DataPlaneRequests", "MongoRequests"]
      }
      if try(app.cosmos_db, null) != null
    },

    # Event Hub
    {
      for app_name, app in var.applications :
      "${app_name}-eventhub" => {
        target_resource_id = try(module.application_event_hubs[app_name].namespace_id, null)
        log_categories     = ["ArchiveLogs", "OperationalLogs"]
      }
      if try(app.event_hub, null) != null
    },
    # =======================================================================
    # ADD THIS BLOCK TO FIX THE MISSING CONTAINER APP LOGS
    # =======================================================================
    # Container App Environment
    {
      for app_name, app in var.applications :
      "${app_name}-cae" => {
        # Logs are configured at the Environment level
        target_resource_id = module.application_cae[app_name].id
        # The specific category for console logs
        log_categories = ["ContainerAppConsoleLogs"]
      }
      # This ensures we add a setting for every application that has a CAE
      if try(app.container_app_environment, null) != null
    },
    # For each application produce a map of its container apps, then merge all maps.
    merge([
      for app_name, app in var.applications :
      try(app.container_apps, {}) == {} ? {} : {
        for container_name, container_app in app.container_apps :
        "${app_name}-${container_name}-ca" => {
          # Reference your existing container_apps module
          target_resource_id = try(module.container_apps["${app_name}-${container_name}"].id, null)

          # Enable system + console logs
          log_categories = []
        }
      }
    ]...)
  )

  # ----------------------------
  # Final merged diagnostics map
  # Add shared settings here so we don’t repeat
  # ----------------------------
  diagnostics = {
    for k, v in merge(local.shared_diagnostics, local.application_diagnostics) :
    k => merge(v, {
      log_analytics_workspace_id = module.logging["main"].workspace_id
      metric_categories          = ["AllMetrics"]
    })
  }
}


output "diagnostics" {
  value = local.diagnostics
}