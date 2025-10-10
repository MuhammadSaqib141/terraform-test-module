data "azurerm_client_config" "current" {}

# =================================================================================
# SECTION 1: CORE & SHARED INFRASTRUCTURE
# Deploys foundational resources shared across all applications in the environment,
# such as resource_groups,container_registries, logging, and api_management.
# =================================================================================

# Creates the fundamental containers for organizing infrastructure and application resources.
module "resource_groups" {
  source      = "./modules/resource_groups"
  for_each    = var.resource_groups
  name        = each.key
  org_prefix  = var.org_prefix
  environment = var.environment
  location    = var.location
  tags        = local.tags
}

module "vnet" {
  for_each = var.virtual_networks

  source = "./modules/vnet"

  name                = each.key
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
  vnet_config         = each.value

  depends_on = [module.resource_groups]
}

# Provisions shared identities, such as for the CI/CD pipeline (app_deployer).
# module "shared_managed_identities" {
#   source              = "./modules/identity"
#   for_each            = var.managed_identities
#   name                = each.key
#   org_prefix          = var.org_prefix
#   environment         = var.environment
#   location            = var.location
#   resource_group_name = module.resource_groups[var.resource_group_infra].name
#   tags                = local.tags
# }

# Establishes the Log Analytics Workspace for collecting logs and metrics from all services.
module "logging" {
  source                  = "./modules/logging"
  for_each                = var.log_analytics_workspaces
  name                    = each.key
  org_prefix              = var.org_prefix
  environment             = var.environment
  location                = var.location
  resource_group_name     = module.resource_groups[var.resource_group_infra].name
  tags                    = local.tags
  log_analytics_workspace = each.value
}

# Creates a shared Azure Container Registry to host Docker images for all applications.
module "container_registries" {
  source              = "./modules/container_registry"
  for_each            = var.container_registries
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
  name                = each.key
  # container_registry  = each.value
  container_registry = merge(each.value, {
    # Add CAE IPs after they're created
    container_app_env_ips = try([
      for app_name, cae in module.application_cae :
      "${cae.static_ip}/32"
    ], [])
  })
}


# Deploys the central API Gateway for managing, securing, and exposing APIs.
module "api_management" {
  source                 = "./modules/api_management"
  for_each               = var.api_management_services
  name                   = each.key
  org_prefix             = var.org_prefix
  environment            = var.environment
  location               = var.location
  resource_group_name    = module.resource_groups[var.resource_group_infra].name
  tags                   = local.tags
  api_management_service = each.value
}


module "front_door" {
  source              = "./modules/front_door"
  org_prefix          = var.org_prefix
  environment         = var.environment
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
  front_doors         = var.front_doors

  # Build map: { apim_name => hostname }
  apim_gateway_hostnames = {
    for apim_name, apim_mod in module.api_management :
    apim_name => replace(apim_mod.gateway_url, "https://", "")
  }
}



# Provisions the shared Azure AI Search service for indexing and querying data.
module "search_service" {
  source = "./modules/search_service"

  name                = "main"
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags

  search_config = var.search_services["main"]
}


# =================================================================================
# SECTION 2: APPLICATION-SPECIFIC INFRASTRUCTURE
# Iterates through the 'applications' map to deploy dedicated resources for each
# defined application, like compute environments, databases, and message queues.
# =================================================================================


# Creates a dedicated Key Vault for each application to store its secrets securely.
module "application_key_vaults" {
  source              = "./modules/key_vault"
  for_each            = var.applications
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
  name                = each.key
  key_vault           = each.value.key_vault
}


# Provisions a unique User-Assigned Managed Identity for each application for secure, passwordless auth.
module "application_managed_identities" {
  source              = "./modules/identity"
  for_each            = var.applications
  name                = each.key
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags
}

# Deploys a dedicated, isolated environment for hosting each application's container apps.
module "application_cae" {
  source                     = "./modules/container_app_environment"
  for_each                   = var.applications
  name                       = each.key
  org_prefix                 = var.org_prefix
  environment                = var.environment
  location                   = var.location
  resource_group_name        = module.resource_groups[var.resource_group_infra].name #module.resource_groups[var.resource_group_app].name
  tags                       = local.tags
  log_analytics_workspace_id = each.value.container_app_environment.log_analytics_workspace_key != null ? module.logging["main"].workspace_id : null

  container_app_environment = {
    log_analytics_workspace_key = each.value.container_app_environment.log_analytics_workspace_key
    zone_redundancy_enabled     = each.value.container_app_environment.zone_redundancy_enabled
    subnet_id                   = local.private_networking_enabled ? module.vnet["main"].subnet_ids["cae-subnet"] : null
    logs_destination            = each.value.container_app_environment.logs_destination
  }

  depends_on = [module.vnet]
}

# Creates Event Hubs namespaces and topics for applications that require event-driven messaging.
module "application_event_hubs" {
  source   = "./modules/event_hub"
  for_each = { for k, v in var.applications : k => v if v.event_hub != null }

  name                = each.key
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_app].name
  tags                = local.tags

  config = merge(
    each.value.event_hub,
    {
      checkpoint_storage_account_name = module.checkpoint_storage.name
      consumer_group_name             = "${replace(each.key, "_", "-")}-consumers"
    }
  )
}


# Provisions Cosmos DB accounts, databases, and containers for applications needing a NoSQL data store.
module "application_cosmos_dbs" {
  source   = "./modules/cosmos_db"
  for_each = { for k, v in var.applications : k => v if v.cosmos_db != null }

  name                = each.key
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_app].name
  tags                = local.tags
  cosmosdb_account    = each.value.cosmos_db
}


# =================================================================================
# SECTION 3: APPLICATION DEPLOYMENT & INTEGRATION
# Deploys the application workloads (Container Apps) and configures their integrations,
# such as Dapr components, APIM endpoints, and AI Search indexing.
# =================================================================================


# Renders and deploys Dapr components (pub/sub, state store, etc.) to the CAE.
module "dapr" {
  source   = "./modules/dapr_component"
  for_each = local.dapr_components

  name                         = each.value.parsed.metadata.name
  container_app_environment_id = local.app_infrastructure[each.value.app_name].cae_id
  type                         = each.value.parsed.spec.type
  dapr_version                 = each.value.parsed.spec.version
  scopes                       = try(each.value.parsed.scopes, [])

  # Pass the parsed metadata from the YAML template
  metadata = [
    for m in each.value.parsed.spec.metadata : {
      name       = m.name
      value      = try(m.value, null)
      secretName = try(m.secretKeyRef.name, null)
    }
  ]

  # Pass the component secrets
  secrets = try(local.component_secrets[each.key], {})
  tags    = local.tags

  # Ensure Key Vault secrets are created first
  depends_on = [
    module.application_key_vaults,
    module.application_secrets #azurerm_key_vault_secret.application_secrets
  ]
}

# Deploys the actual application microservices (e.g., order-api, order-worker) as Container Apps.
module "container_apps" {
  source   = "./modules/container_app"
  for_each = local.all_container_apps

  name                         = each.value.ca_name
  org_prefix                   = var.org_prefix
  environment                  = var.environment
  location                     = var.location
  resource_group_name          = module.resource_groups[var.resource_group_app].name
  container_app_environment_id = module.application_cae[each.value.app_name].id
  registry_server              = module.container_registries["main"].registry_login_server
  tags                         = local.tags
  user_assigned_identity_id    = module.application_managed_identities[each.value.app_name].id
  container_app                = each.value.config

  # Ensure Container Apps are deployed after Dapr components are ready
  depends_on = [
    time_sleep.wait_for_cae_provisioning,
    module.dapr,
    time_sleep.wait_for_rbac_propagation
  ]
}


# Configures AI Search datasources, indexes, and indexers using the REST API via `local-exec`.
# This imperative approach is used to manage complex search schemas defined in the application's configuration.
module "search_configuration" {
  source   = "./modules/search_configuration"
  for_each = { for k, v in var.applications : k => v if try(v.search_setup, null) != null }


  search_endpoint  = module.search_service.endpoint
  search_admin_key = module.search_service.primary_key

  search_setup = {
    # The datasource config is a merge of the static definition from the .tfvars file
    # and the dynamically-generated credentials.
    datasource = {
      name                        = each.value.search_setup.datasource.name
      type                        = each.value.search_setup.datasource.type
      container                   = each.value.search_setup.datasource.container
      dataChangeDetectionPolicy   = each.value.search_setup.datasource.dataChangeDetectionPolicy
      dataDeletionDetectionPolicy = each.value.search_setup.datasource.dataDeletionDetectionPolicy

      # Dynamically inject the credentials using the output from the cosmos_db module
      credentials = {
        connectionString = "${module.application_cosmos_dbs[each.key].connection_string};Database=${each.value.cosmos_db.sql_database.database_name}"
      }
    }
    index   = each.value.search_setup.index
    indexer = each.value.search_setup.indexer
  }

  depends_on = [
    module.search_service,
    module.application_cosmos_dbs
  ]
}


# Creates and configures the APIs, operations, and policies within the central APIM service.
# Each application defines its own API structure and policies in the `apim_configs` block of the .tfvars file.
module "apim_configs" {
  source   = "./modules/apim_configs"
  for_each = { for k, v in var.applications : k => v if try(v.apim_configs, null) != null }

  org_prefix                = var.org_prefix
  environment               = var.environment
  resource_group_name       = module.resource_groups[var.resource_group_infra].name
  api_management_name       = module.api_management["main"].name
  tags                      = local.tags
  app_name                  = each.key
  apim_configs              = each.value.apim_configs
  search_service_endpoint   = module.search_service.endpoint
  search_index_name         = each.value.search_setup.index.name
  search_api_version        = "2023-11-01"
  ai_search_query_secret_id = module.application_secrets.secrets["${each.key}-ai-search-query-key"].id

  depends_on = [
    module.application_secrets,
    time_sleep.wait_for_apim_kv_permissions
  ]
}


# =================================================================================
# SECTION 4: SUPPORTING & UTILITY RESOURCES
# Provisions miscellaneous but critical resources like storage for checkpoints
# and centralized secret management.
# =================================================================================

# Provisions a shared Azure Storage Account required by the Dapr pub/sub component.
# Dapr uses this storage to save checkpoints, ensuring reliable, at-least-once message 
module "checkpoint_storage" {
  source              = "./modules/storage_account"
  name                = "ehcheckpoints"
  org_prefix          = var.org_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_app].name
  tags                = local.tags

  storage_config = {
    account_tier             = "Standard"
    account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
    account_kind             = "StorageV2"
    min_tls_version          = "TLS1_2"

    blob_properties = {
      versioning_enabled = false
      delete_retention_policy = {
        days = var.environment == "prod" ? 30 : 7
      }
    }
  }
}

# Populates each application's Key Vault with dynamically generated secrets, such as
# connection strings for Event Hubs, primary keys for Cosmos DB, and keys for AI Search.
module "application_secrets" {
  source  = "./modules/secrets_management"
  secrets = local.application_secrets
  tags    = local.tags

  depends_on = [
    module.application_key_vaults,
    module.application_event_hubs,
    module.application_cosmos_dbs,
    module.checkpoint_storage
  ]
}

module "diagnostics" {
  source      = "./modules/diagnostics"
  diagnostics = local.diagnostics
  # resource_group_name = module.resource_groups[var.resource_group_infra].name
  # log_analytics_workspace = module.logging["main"].workspace_id
  # location    = var.location
}

# NEW module call for alerts
module "monitoring_alerts" {
  source = "./modules/monitoring_alerts"

  location            = var.location
  resource_group_name = module.resource_groups[var.resource_group_infra].name
  tags                = local.tags

  log_analytics_workspace_id = module.logging["main"].workspace_id

  # Pass the declarative configurations from variables
  action_groups   = var.action_groups
  log_alert_rules = var.log_alert_rules
}