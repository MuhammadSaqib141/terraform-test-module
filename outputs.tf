# =================================================================================
# SECTION 1: CORE & SHARED INFRASTRUCTURE OUTPUTS
# Outputs for foundational resources shared across all applications.
# =================================================================================

output "resource_group_names" {
  description = "A map of the deployed shared resource group names."
  value       = { for k, rg in module.resource_groups : k => rg.name }
}

# output "shared_managed_identity_principal_ids" {
#   description = "A map of Principal IDs for the shared managed identities (e.g., for CI/CD)."
#   value       = { for k, id in module.shared_managed_identities : k => id.principal_id }
#   sensitive   = true
# }

output "log_analytics_workspace_ids" {
  description = "A map of the deployed shared Log Analytics Workspace IDs."
  value       = { for k, ws in module.logging : k => ws.workspace_id }
}

output "container_registry_login_servers" {
  description = "Map of Azure Container Registry (ACR) login servers."
  value       = { for k, acr in module.container_registries : k => acr.registry_login_server }
}

output "container_registry_names" {
  description = "A simplified map of the deployed container registry names."
  value = {
    for k, acr in module.container_registries : k => acr.registry_name
  }
}

# remove it
output "container_registry_naming" {
  description = "A simplified map of the deployed container registry names."
  value = {
    for k, acr in module.container_registries : k => acr.registry_name
  }
}

output "api_management_gateway_urls" {
  description = "A map of the gateway URLs for the shared API Management services."
  value       = { for k, apim in module.api_management : k => apim.gateway_url }
}

output "search_service_endpoint" {
  description = "The endpoint URL for the shared Azure AI Search service."
  value       = module.search_service.endpoint
  sensitive   = true
}

# =================================================================================
# SECTION 2: APPLICATION-SPECIFIC INFRASTRUCTURE OUTPUTS
# Outputs for dedicated resources deployed for each application.
# =================================================================================

output "application_key_vault_uris" {
  description = "A map of the URIs for each application-specific Key Vault."
  value       = { for k, kv in module.application_key_vaults : k => kv.uri }
}

output "application_managed_identity_principal_ids" {
  description = "A map of Principal IDs for each application's specific managed identity."
  value       = { for k, mi in module.application_managed_identities : k => mi.principal_id }
  sensitive   = true
}

output "application_container_app_environment_ids" {
  description = "A map of the resource IDs for each application's Container App Environment."
  value       = { for k, cae in module.application_cae : k => cae.id }
}

output "application_event_hubs" {
  description = "A map of all outputs from the application-specific Event Hub modules, including names and connection strings."
  value       = module.application_event_hubs
  sensitive   = true
}

output "application_cosmos_dbs" {
  description = "A map of all outputs from the application-specific Cosmos DB modules, including endpoints and connection strings."
  value       = module.application_cosmos_dbs
  sensitive   = true
}

# =================================================================================
# SECTION 3: APPLICATION DEPLOYMENT & INTEGRATION OUTPUTS
# Outputs related to the deployed application workloads and their integrations.
# =================================================================================

output "container_app_urls" {
  description = "A map of the fully qualified domain names (FQDNs) for all container apps with ingress enabled."
  value       = { for k, app in module.container_apps : k => app.fqdn if app.fqdn != null }
}

output "search_configurations" {
  description = "A map detailing the created AI Search components (datasource, index, indexer) for each application."
  value = {
    for k, v in module.search_configuration : k => {
      datasource_name = v.datasource_name
      index_name      = v.index_name
      indexer_name    = v.indexer_name
    }
  }
}

output "deployment_summary" {
  description = "A comprehensive summary of the deployed applications and their associated components and infrastructure."
  value = {
    applications = keys(var.applications)
    components_per_app = {
      for app_name in keys(var.applications) : app_name => {
        apis            = local.app_components[app_name].apis
        workers         = local.app_components[app_name].workers
        dapr_components = [for key, comp in local.dapr_components : comp.parsed.metadata.name if comp.app_name == app_name]
      }
    }
    infrastructure_summary = {
      for app_name in keys(var.applications) : app_name => {
        key_vault_name      = local.app_infrastructure[app_name].keyvault_name
        event_hub_namespace = try(local.app_infrastructure[app_name].eventhub_namespace, "not configured")
        cosmos_db_url       = try(local.app_infrastructure[app_name].cosmos_url, "not configured")
      }
    }
  }
  sensitive = true
}

# =================================================================================
# SECTION 4: SUPPORTING & UTILITY RESOURCES OUTPUTS
# Outputs for miscellaneous but critical supporting resources.
# =================================================================================

output "checkpoint_storage_account_name" {
  description = "The name of the shared storage account used for Event Hub checkpointing."
  value       = module.checkpoint_storage.name
}

output "application_secret_ids" {
  description = "A map of all secret IDs created in the various application Key Vaults."
  value       = { for k, v in module.application_secrets.secrets : k => v.id }
  sensitive   = true
}
# =================================================================================
# SECTION 5: LOCALS INSPECTION OUTPUTS
# Purpose: For debugging and understanding the values computed in the locals.tf file.
# =================================================================================

output "local_tags" {
  description = "INSPECT: The final merged map of tags applied to all resources."
  value       = local.tags
}

output "local_all_container_apps" {
  description = "INSPECT: The flattened map of all container apps, keyed by a unique name."
  value       = local.all_container_apps
  sensitive   = true
}

output "local_app_components" {
  description = "INSPECT: A map categorizing container apps into 'apis' and 'workers' for each application."
  value       = local.app_components
}

output "local_app_infrastructure_references" {
  description = "INSPECT: A consolidated map of key infrastructure details (URLs, names, IDs) for each application."
  value       = local.app_infrastructure
  sensitive   = true
}

output "local_dapr_components_rendered" {
  description = "INSPECT: The final, rendered Dapr component objects after processing templates."
  value       = local.dapr_components
  sensitive   = true
}

output "local_component_secrets" {
  description = "INSPECT: A map of secrets that are being passed to Dapr components."
  value       = local.component_secrets
  sensitive   = true
}

output "local_application_secrets_to_be_created" {
  description = "INSPECT: The map of secrets configured to be created in application key vaults."
  value       = local.application_secrets
  sensitive   = true
}

output "debug_private_container_registries" {
  description = "INSPECT: debug_private_container_registries."
  value       = local.private_container_registries
}