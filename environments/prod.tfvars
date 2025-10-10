# -----------------------------------------------------------------------------
# Core Environment Settings
# -----------------------------------------------------------------------------
environment = "prod"

# -----------------------------------------------------------------------------
# Common Tags - Merged with default tags in main.tf
# -----------------------------------------------------------------------------
common_tags = {
  owner           = "OpsTeam"
  cost-center     = "5678-PROD"
  support-contact = "support@example.com"
}


admin_user_object_id = "xxxx-xxxx-xxxx-xxx-xxxxx"

# -----------------------------------------------------------------------------
# logging Settings
# -----------------------------------------------------------------------------
# Production logs should be kept for longer for auditing and analysis.
log_analytics_retention_in_days = 90
# apim_sku_name = "Standard"