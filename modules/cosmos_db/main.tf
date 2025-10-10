resource "azurerm_cosmosdb_account" "main" {
  name                                  = "${replace(var.org_prefix, "-", "")}-${var.environment}-${replace(var.name, "_", "-")}-cosmos"
  resource_group_name                   = var.resource_group_name
  location                              = var.location
  offer_type                            = var.cosmosdb_account.offer_type
  kind                                  = var.cosmosdb_account.kind
  ip_range_filter                       = var.cosmosdb_account.allowed_ip_range_cidrs #join(",", var.cosmosdb_account.allowed_ip_range_cidrs)
  analytical_storage_enabled            = var.cosmosdb_account.analytical_storage_enabled
  automatic_failover_enabled            = var.cosmosdb_account.automatic_failover_enabled
  public_network_access_enabled         = var.cosmosdb_account.public_network_access_enabled
  is_virtual_network_filter_enabled     = var.cosmosdb_account.is_virtual_network_filter_enabled
  key_vault_key_id                      = var.cosmosdb_account.key_vault_key_id
  multiple_write_locations_enabled      = var.cosmosdb_account.multiple_write_locations_enabled
  access_key_metadata_writes_enabled    = var.cosmosdb_account.access_key_metadata_writes_enabled
  mongo_server_version                  = var.cosmosdb_account.kind == "MongoDB" ? var.cosmosdb_account.mongo_server_version : null
  network_acl_bypass_for_azure_services = var.cosmosdb_account.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = var.cosmosdb_account.network_acl_bypass_ids
  tags                                  = var.tags

  consistency_policy {
    consistency_level       = var.cosmosdb_account.consistency_policy.consistency_level
    max_interval_in_seconds = var.cosmosdb_account.consistency_policy.consistency_level == "BoundedStaleness" ? var.cosmosdb_account.consistency_policy.max_interval_in_seconds : null
    max_staleness_prefix    = var.cosmosdb_account.consistency_policy.consistency_level == "BoundedStaleness" ? var.cosmosdb_account.consistency_policy.max_staleness_prefix : null
  }

  dynamic "geo_location" {
    for_each = length(var.cosmosdb_account.geo_locations) > 0 ? var.cosmosdb_account.geo_locations : [
      {
        location          = var.location
        failover_priority = 0
        zone_redundant    = false
      }
    ]
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = lookup(geo_location.value, "zone_redundant", false)
    }
  }

  dynamic "capabilities" {
    for_each = toset(var.cosmosdb_account.capabilities)
    content {
      name = capabilities.key
    }
  }

  dynamic "virtual_network_rule" {
    for_each = var.cosmosdb_account.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = lookup(virtual_network_rule.value, "ignore_missing_vnet_service_endpoint", false)
    }
  }

  dynamic "backup" {
    for_each = var.cosmosdb_account.backup != null ? [var.cosmosdb_account.backup] : []
    content {
      type                = var.cosmosdb_account.backup.type
      interval_in_minutes = lookup(var.cosmosdb_account.backup, "interval_in_minutes", null)
      retention_in_hours  = lookup(var.cosmosdb_account.backup, "retention_in_hours", null)
    }
  }

  dynamic "cors_rule" {
    for_each = var.cosmosdb_account.cors_rules != null ? [var.cosmosdb_account.cors_rules] : []
    content {
      allowed_headers    = var.cosmosdb_account.cors_rules.allowed_headers
      allowed_methods    = var.cosmosdb_account.cors_rules.allowed_methods
      allowed_origins    = var.cosmosdb_account.cors_rules.allowed_origins
      exposed_headers    = var.cosmosdb_account.cors_rules.exposed_headers
      max_age_in_seconds = var.cosmosdb_account.cors_rules.max_age_in_seconds
    }
  }

  dynamic "identity" {
    for_each = var.cosmosdb_account.managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_account.sql_database.database_name
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name

  throughput = var.cosmosdb_account.sql_database.autoscale_settings == null ? var.cosmosdb_account.sql_database.throughput : null

  dynamic "autoscale_settings" {
    for_each = var.cosmosdb_account.sql_database.autoscale_settings != null ? [var.cosmosdb_account.sql_database.autoscale_settings] : []
    content {
      max_throughput = var.cosmosdb_account.sql_database.throughput == null ? autoscale_settings.value.max_throughput : null
    }
  }
}



resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_account.sql_container.name
  resource_group_name   = azurerm_cosmosdb_account.main.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths   = var.cosmosdb_account.sql_container.partition_key_paths
  partition_key_version = var.cosmosdb_account.sql_container.partition_key_version

  throughput = var.cosmosdb_account.sql_container.autoscale_settings == null ? var.cosmosdb_account.sql_container.throughput : null

  default_ttl            = var.cosmosdb_account.sql_container.default_ttl
  analytical_storage_ttl = var.cosmosdb_account.sql_container.analytical_storage_ttl

  dynamic "unique_key" {
    for_each = var.cosmosdb_account.sql_container.unique_key != null ? [var.cosmosdb_account.sql_container.unique_key] : []
    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "autoscale_settings" {
    for_each = var.cosmosdb_account.sql_container.autoscale_settings != null ? [var.cosmosdb_account.sql_container.autoscale_settings] : []
    content {
      max_throughput = var.cosmosdb_account.sql_container.throughput == null ? autoscale_settings.value.max_throughput : null
    }
  }

  dynamic "indexing_policy" {
    for_each = var.cosmosdb_account.sql_container.indexing_policy != null ? [var.cosmosdb_account.sql_container.indexing_policy] : []
    content {
      indexing_mode = indexing_policy.value.indexing_mode

      dynamic "included_path" {
        for_each = lookup(indexing_policy.value, "included_path", null) != null ? [indexing_policy.value.included_path] : []
        content {
          path = included_path.value.path
        }
      }

      dynamic "excluded_path" {
        for_each = lookup(indexing_policy.value, "excluded_path", null) != null ? [indexing_policy.value.excluded_path] : []
        content {
          path = excluded_path.value.path
        }
      }

      dynamic "composite_index" {
        for_each = lookup(indexing_policy.value, "composite_index", null) != null ? [indexing_policy.value.composite_index] : []
        content {
          index {
            path  = composite_index.value.index.path
            order = composite_index.value.index.order
          }
        }
      }

      dynamic "spatial_index" {
        for_each = lookup(indexing_policy.value, "spatial_index", null) != null ? [indexing_policy.value.spatial_index] : []
        content {
          path = spatial_index.value.path
        }
      }
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = var.cosmosdb_account.sql_container.conflict_resolution_policy != null ? [var.cosmosdb_account.sql_container.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = lookup(conflict_resolution_policy.value, "conflict_resolution_path", null)
      conflict_resolution_procedure = lookup(conflict_resolution_policy.value, "conflict_resolution_procedure", null)
    }
  }
}
