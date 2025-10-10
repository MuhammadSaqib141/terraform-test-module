# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

resource "azurerm_role_assignment" "apim_kv_secrets_reader" {
  # This should loop for every application that uses APIM to access its KV
  for_each = { for k, v in var.applications : k => v if try(v.apim_configs, null) != null }

  scope                = module.application_key_vaults[each.key].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.api_management["main"].system_assigned_identity_principal_id

  depends_on = [
    module.application_key_vaults,
    module.api_management,
  ]
}

# --- Permissions for Each Application's Identity ---
resource "azurerm_role_assignment" "app_acrpull" {
  for_each             = var.applications
  scope                = module.container_registries["main"].registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.application_managed_identities[each.key].principal_id

  depends_on = [
    module.container_registries["main"],
    module.application_managed_identities
  ]
}

resource "azurerm_role_assignment" "app_self_kv_access" {
  for_each             = var.applications
  scope                = module.application_key_vaults[each.key].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.application_managed_identities[each.key].principal_id

  depends_on = [
    module.application_key_vaults,
    module.application_managed_identities
  ]
}

# --- ADD the permissions for the CI/CD Pipeline Identity for later use (app_deployer) ---
# resource "azurerm_role_assignment" "deployer_acrpull" {
#   scope                = module.container_registries["main"].registry_id
#   role_definition_name = "AcrPush"
#   principal_id         = module.shared_managed_identities["app_deployer"].principal_id

#   depends_on = [
#     module.container_registries["main"],
#     module.shared_managed_identities
#   ]
# }

# resource "azurerm_role_assignment" "deployer_contributor_on_apps_rg" {
#   scope                = module.resource_groups[var.resource_group_app].id
#   role_definition_name = "Contributor"
#   principal_id         = module.shared_managed_identities["app_deployer"].principal_id

#   depends_on = [
#     module.resource_groups,
#     module.shared_managed_identities
#   ]
# }

# resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
#   for_each             = var.applications
#   scope                = module.application_key_vaults[each.key].id
#   role_definition_name = "Key Vault Secrets Officer"
#   principal_id         = module.shared_managed_identities["app_deployer"].principal_id

#   depends_on = [
#     module.application_key_vaults,
#     module.shared_managed_identities
#   ]
# }


resource "azurerm_role_assignment" "app_storage_blob_data_contributor" {
  for_each             = var.applications
  scope                = module.checkpoint_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.application_managed_identities[each.key].principal_id

  depends_on = [
    module.checkpoint_storage,
    module.application_managed_identities
  ]
}



# Grant Search Service read-only access to Cosmos DB (Least Privilege)
resource "azurerm_role_assignment" "search_cosmos_reader" {
  for_each = { for k, v in var.applications : k => v if try(v.search_setup, null) != null && v.cosmos_db != null }

  scope                = module.application_cosmos_dbs[each.key].account_id # Now this should work
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = module.search_service.identity_principal_id

  depends_on = [
    module.search_service,
    module.application_cosmos_dbs
  ]
}
