resource "time_sleep" "wait_for_cae_provisioning" {
  create_duration = "60s"
  depends_on      = [module.application_cae, module.dapr]
}

resource "time_sleep" "wait_for_apim_kv_permissions" {
  depends_on = [
    module.api_management,
    azurerm_role_assignment.apim_kv_secrets_reader
  ]
  create_duration = "30s"
}

resource "time_sleep" "wait_for_rbac_propagation" {
  depends_on      = [azurerm_role_assignment.app_acrpull]
  create_duration = "60s"
}