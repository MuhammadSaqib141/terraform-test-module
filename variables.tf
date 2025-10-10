variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize resource names (e.g., 'ordertracking')."
  default     = "ordertracking"
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'stage', 'prod')."
}

variable "location" {
  type        = string
  description = "The primary Azure region where resources will be deployed."
  default     = "eastus"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of common tags applied to all resources. These are merged with default tags for governance and cost tracking."
  default     = {}
}

# variable "admin_user_object_id" {
#   type        = string
#   description = "The Azure AD Object ID of the user or group granted initial admin rights on shared resources such as Key Vaults."
#   sensitive   = true
# }

variable "resource_group_infra" {
  type        = string
  description = "The name of the Azure Resource Group for shared infrastructure resources (e.g., Key Vaults, managed identities)."
}

variable "resource_group_app" {
  type        = string
  description = "The name of the Azure Resource Group for application-specific resources (e.g., Container App Environments)."
}

# =============================================================================
# SHARED INFRASTRUCTURE VARIABLES
# =============================================================================

variable "resource_groups" {
  type        = map(object({}))
  description = "A map of shared resource groups to create. The key is a logical name, and the value defines the group properties."
  default     = {}
}

variable "managed_identities" {
  type        = map(object({}))
  description = "A map of shared User-Assigned Managed Identities to create. The key is a logical name, and the value defines identity properties."
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "A map of Log Analytics Workspaces to create, keyed by logical names. Used for diagnostics and monitoring."
  type = map(object({
    name                               = string
    allow_resource_only_permissions    = optional(bool, true)
    local_authentication_disabled      = optional(bool, true)
    sku                                = optional(string, "PerGB2018")
    retention_in_days                  = optional(number, 30)
    daily_quota_gb                     = optional(number, -1)
    cmk_for_query_forced               = optional(bool, false)
    internet_ingestion_enabled         = optional(bool, true)
    internet_query_enabled             = optional(bool, true)
    reservation_capacity_in_gb_per_day = optional(number, null)
    data_collection_rule_id            = optional(string, null)
  }))
  default = {}
}

variable "container_registries" {
  description = "A map of Azure Container Registries to create. Defines registry configuration, networking, and replication."
  type = map(object({
    sku                             = string
    admin_enabled                   = optional(bool, false)
    public_network_access_enabled   = optional(bool, true)
    network_rule_bypass_option      = optional(string, "AzureServices")
    network_rule_set_default_action = optional(string, "Allow")
    network_rule_set_ip_rules       = optional(list(string), [])
    agent_public_ip                 = optional(string, null)
    container_app_env_ips           = optional(list(string), [])
    georeplications = optional(list(object({
      location                = string
      zone_redundancy_enabled = bool
    })), [])
  }))
  default = {}
}

variable "search_services" {
  description = "Configuration for Azure AI Search services"
  type = map(object({
    sku                           = string
    partition_count               = optional(number, 1)
    replica_count                 = optional(number, 1)
    public_network_access_enabled = optional(bool, true)
    identity = optional(object({
      type         = string # SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned
      identity_ids = optional(list(string), null)
    }), null)
    allowed_ips                              = optional(list(string), null)
    authentication_failure_mode              = optional(string, null) # Possible values: http401WithBearerChallenge, http403
    customer_managed_key_enforcement_enabled = optional(bool, false)
    hosting_mode                             = optional(string, "default") # Possible values: default, highDensity
    network_rule_bypass_option               = optional(string, "None")    # Possible values: None, AzureServices
    semantic_search_sku                      = optional(string, null)      # Possible values: free, standard


  }))
  default = {}
}



variable "api_management_services" {
  description = "A map of Azure API Management (APIM) services to create, keyed by logical names."
  type = map(object({
    publisher_name                      = string
    publisher_email                     = string
    sku_name                            = string
    system_assigned_identity            = optional(bool, true)
    user_assigned_identity_resource_ids = optional(list(string), [])
    virtual_network_subnet_id           = optional(string, null)
  }))
  default = {}
}

variable "front_doors" {
  description = "A map of Azure Front Door services to create, keyed by logical names."
  type = map(object({
    sku_name = string
    waf_policy = object({
      enabled = bool
      mode    = string
    })
  }))
  default = {}
}

# =============================================================================
# APPLICATION-SPECIFIC INFRASTRUCTURE VARIABLE (with strong type)
# =============================================================================

variable "applications" {
  description = "A map of application-specific infrastructure to deploy, keyed by a unique application name."
  default     = {}
  type = map(object({
    # --- Container App Environment Configuration ---
    container_app_environment = object({
      log_analytics_workspace_key = string
      zone_redundancy_enabled     = optional(bool, false)
      infrastructure_subnet_id    = optional(string, null)
      logs_destination            = optional(string, "azure-monitor")
    })

    # --- Managed Identity Configuration ---
    managed_identity = object({})

    # --- Key Vault Configuration ---
    key_vault = object({
      sku_name                      = string
      soft_delete_retention_days    = number
      purge_protection_enabled      = bool
      enable_rbac_authorization     = bool
      public_network_access_enabled = bool
      network_acls = optional(object({
        default_action = string
        bypass         = string
        ip_rules       = optional(list(string), [])
      }), null)
    })

    # --- Container Apps within an application ---
    container_apps = optional(map(object({
      image_name   = string
      image_tag    = string
      cpu          = number
      memory       = string
      min_replicas = number
      max_replicas = number
      ingress = object({
        enabled     = bool
        target_port = optional(number)
      })
    })), {})


    # --- Event Hub Configuration ---
    event_hub = optional(object({
      # Core Event Hub configs
      resource_group_key = string
      hub_name           = string
      partition_count    = number
      message_retention  = number

      # Namespace configs
      sku                           = optional(string, "Standard")
      capacity                      = optional(number, 2)
      auto_inflate_enabled          = optional(bool, false)
      dedicated_cluster_id          = optional(string)
      maximum_throughput_units      = optional(number)
      local_authentication_enabled  = optional(bool)
      public_network_access_enabled = optional(bool, true)
      minimum_tls_version           = optional(string, "1.2")

      # Network rules
      network_rules_enabled                  = optional(bool, false)
      network_rules_default_action           = optional(string, "Deny")
      network_trusted_service_access_enabled = optional(bool, true)
      allowed_cidrs                          = optional(list(string), [])
      allowed_subnet_ids                     = optional(list(string), [])
    }))

    # --- Cosmos DB Configuration ---
    cosmos_db = optional(object({
      # Required
      resource_group_key = optional(string)
      offer_type         = optional(string, "Standard")
      kind               = optional(string, "GlobalDocumentDB")

      sql_database = object({
        database_name = string
        throughput    = optional(number, null)
        autoscale_settings = optional(object({
          max_throughput = number
        }), null)
      })

      sql_container = optional(object({
        name                  = string
        partition_key_paths   = list(string)
        partition_key_version = optional(number)
        throughput            = optional(number)
        autoscale_settings = optional(object({
          max_throughput = number
        }))
        default_ttl            = optional(number, null)
        analytical_storage_ttl = optional(number, null)

        unique_key = optional(object({
          paths = list(string)
        }), null)

        indexing_policy = optional(object({
          indexing_mode = string
          included_path = optional(object({ path = string }))
          excluded_path = optional(object({ path = string }))
          composite_index = optional(object({
            index = object({
              path  = string
              order = string
            })
          }))
          spatial_index = optional(object({ path = string }))
        }), null)

        conflict_resolution_policy = optional(object({
          mode                          = string
          conflict_resolution_path      = optional(string)
          conflict_resolution_procedure = optional(string)
        }), null)
      }), null)

      # Optional general settings
      tags                                  = optional(map(string), {})
      allowed_ip_range_cidrs                = optional(list(string), [])
      minimal_tls_version                   = optional(string, "Tls12") # Tls, Tls11, Tls12 (default: Tls12)
      free_tier_enabled                     = optional(bool, false)
      create_mode                           = optional(string, "Default")            # Default | Restore
      default_identity_type                 = optional(string, "FirstPartyIdentity") # FirstPartyIdentity | SystemAssignedIdentity | UserAssignedIdentity
      analytical_storage_enabled            = optional(bool, false)
      automatic_failover_enabled            = optional(bool, false)
      partition_merge_enabled               = optional(bool, false)
      burst_capacity_enabled                = optional(bool, false)
      public_network_access_enabled         = optional(bool, true)
      is_virtual_network_filter_enabled     = optional(bool, false)
      key_vault_key_id                      = optional(string, null)
      managed_hsm_key_id                    = optional(string, null)
      multiple_write_locations_enabled      = optional(bool, false)
      access_key_metadata_writes_enabled    = optional(bool, true)
      mongo_server_version                  = optional(string, "4.2")
      network_acl_bypass_for_azure_services = optional(bool, false)
      network_acl_bypass_ids                = optional(list(string), [])
      local_authentication_disabled         = optional(bool, false)

      # Consistency
      consistency_policy = optional(object({
        consistency_level       = string
        max_interval_in_seconds = optional(number, 5)
        max_staleness_prefix    = optional(number, 100)
        }), {
        consistency_level       = "BoundedStaleness"
        max_interval_in_seconds = 5
        max_staleness_prefix    = 100
      })

      # Geo Locations (✅ default added)
      geo_locations = optional(list(object({
        location          = string
        failover_priority = number
        zone_redundant    = optional(bool, false)
      })), [])

      # Capabilities
      capabilities = optional(list(string), [])

      # VNet Rules
      virtual_network_rules = optional(list(object({
        id                                   = string
        ignore_missing_vnet_service_endpoint = optional(bool, false)
      })), [])

      # Backup
      backup = optional(object({
        type                = string           # Periodic | Continuous
        interval_in_minutes = optional(number) # Only for Periodic
        retention_in_hours  = optional(number) # Only for Periodic
      }), null)

      # CORS
      cors_rules = optional(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      }), null)

      # Identity
      managed_identity = optional(bool, false) # SystemAssigned
    }))

    # -------------------------------------------------------------------------
    # CORRECTED SECTION: The new, declarative search setup is defined here.
    # -------------------------------------------------------------------------
    search_setup = optional(object({
      datasource = object({
        name                        = string
        type                        = string
        container                   = any
        dataChangeDetectionPolicy   = optional(any)
        dataDeletionDetectionPolicy = optional(any)
      })
      index = object({
        name       = string
        fields     = list(any)
        suggesters = optional(list(any), [])
      })
      indexer = object({
        name     = string
        schedule = optional(string, "PT5M")
      })
    }))
    # APIs definition for APIM
    apim_configs = optional(object({
      api = object({
        name         = string
        display_name = optional(string, null)
        path         = optional(string, null)
        protocols    = optional(list(string), null)
        revision     = string
        # Optional
        api_type              = optional(string, "http")
        description           = optional(string, null)
        service_url           = optional(string, null)
        subscription_required = optional(bool, true)
        version               = optional(string, null)
        version_set_id        = optional(string, null)
        revision_description  = optional(string, null)
        version_description   = optional(string, null)
        source_api_id         = optional(string, null)
        terms_of_service_url  = optional(string, null)

        contact = optional(object({
          email = optional(string, null)
          name  = optional(string, null)
          url   = optional(string, null)
        }), null)

        license = optional(object({
          name = optional(string, null)
          url  = optional(string, null)
        }), null)

        import = optional(object({
          content_format = string
          content_value  = string
          wsdl_selector = optional(object({
            service_name  = string
            endpoint_name = string
          }), null)
        }), null)

        oauth2_authorization = optional(object({
          authorization_server_name = string
          scope                     = optional(string, null)
        }), null)

        openid_authentication = optional(object({
          openid_provider_name         = string
          bearer_token_sending_methods = optional(list(string), null)
        }), null)

        subscription_key_parameter_names = optional(object({
          header = string
          query  = string
        }), null)
      })

      operations = list(object({
        operation_id = string
        display_name = string
        method       = string
        url_template = string
        description  = optional(string, null)

        request = optional(object({
          description = optional(string, null)

          header = optional(list(object({
            name          = string
            required      = bool
            type          = string
            description   = optional(string, null)
            default_value = optional(string, null)
            values        = optional(list(string), null)
            schema_id     = optional(string, null)
            type_name     = optional(string, null)
            example = optional(list(object({
              name           = string
              summary        = optional(string, null)
              description    = optional(string, null)
              value          = optional(string, null)
              external_value = optional(string, null)
            })), null)
          })), null)

          query_parameter = optional(list(object({
            name          = string
            required      = bool
            type          = string
            description   = optional(string, null)
            default_value = optional(string, null)
            values        = optional(list(string), null)
            schema_id     = optional(string, null)
            type_name     = optional(string, null)
            example = optional(list(object({
              name           = string
              summary        = optional(string, null)
              description    = optional(string, null)
              value          = optional(string, null)
              external_value = optional(string, null)
            })), null)
          })), null)

          representation = optional(list(object({
            content_type = string
            schema_id    = optional(string, null)
            type_name    = optional(string, null)

            example = optional(list(object({
              name           = string
              summary        = optional(string, null)
              description    = optional(string, null)
              value          = optional(string, null)
              external_value = optional(string, null)
            })), null)

            form_parameter = optional(list(object({
              name          = string
              required      = bool
              type          = string
              description   = optional(string, null)
              default_value = optional(string, null)
              values        = optional(list(string), null)
              schema_id     = optional(string, null)
              type_name     = optional(string, null)
              example = optional(list(object({
                name           = string
                summary        = optional(string, null)
                description    = optional(string, null)
                value          = optional(string, null)
                external_value = optional(string, null)
              })), null)
            })), null)
          })), null)
        }), null)

        response = optional(list(object({
          status_code = number
          description = optional(string, null)

          header = optional(list(object({
            name          = string
            required      = bool
            type          = string
            description   = optional(string, null)
            default_value = optional(string, null)
            values        = optional(list(string), null)
            schema_id     = optional(string, null)
            type_name     = optional(string, null)
            example = optional(list(object({
              name           = string
              summary        = optional(string, null)
              description    = optional(string, null)
              value          = optional(string, null)
              external_value = optional(string, null)
            })), null)
          })), null)

          representation = optional(list(object({
            content_type = string
            schema_id    = optional(string, null)
            type_name    = optional(string, null)

            example = optional(list(object({
              name           = string
              summary        = optional(string, null)
              description    = optional(string, null)
              value          = optional(string, null)
              external_value = optional(string, null)
            })), null)

            form_parameter = optional(list(object({
              name          = string
              required      = bool
              type          = string
              description   = optional(string, null)
              default_value = optional(string, null)
              values        = optional(list(string), null)
              schema_id     = optional(string, null)
              type_name     = optional(string, null)
              example = optional(list(object({
                name           = string
                summary        = optional(string, null)
                description    = optional(string, null)
                value          = optional(string, null)
                external_value = optional(string, null)
              })), null)
            })), null)
          })), null)
        })), null)

        template_parameter = optional(list(object({
          name          = string
          required      = bool
          type          = string
          description   = optional(string, null)
          default_value = optional(string, null)
          values        = optional(list(string), null)
          schema_id     = optional(string, null)
          type_name     = optional(string, null)
          example = optional(list(object({
            name           = string
            summary        = optional(string, null)
            description    = optional(string, null)
            value          = optional(string, null)
            external_value = optional(string, null)
          })), null)
        })), null)
      }))

      policy_file   = optional(string, null)
      jwt_audiences = optional(list(string), [])
      jwt_issuers   = optional(list(string), [])
      cors = optional(object({
        allow_credentials = optional(string, "false")
        allowed_origins   = optional(list(string), ["*"])
        allowed_methods   = optional(list(string), ["GET", "POST", "OPTIONS"])
        allowed_headers   = optional(list(string), ["*"])
        expose_headers    = optional(list(string), ["*"])
        preflight_max_age = optional(number, 300)
      }), null)

      rate_limit = optional(object({
        calls          = optional(number, 100)
        renewal_period = optional(number, 60)
      }), null)
    }), null)
  }))
}

variable "virtual_networks" {
  description = "A map of virtual networks to create, including their subnets and associated network security groups with rules."
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
      # NSG optional hai, har subnet ke liye zaroori nahi.
      network_security_group = optional(object({
        rules = list(object({
          name                       = string
          priority                   = number
          direction                  = string
          access                     = string
          protocol                   = string
          source_port_range          = string
          destination_port_range     = string
          source_address_prefix      = string
          destination_address_prefix = string
        }))
      }))
    }))
  }))
  default = {}
}

variable "agent_rg_name" {
  description = "The resource group name where the self-hosted agent's VNet is located."
  type        = string
  default     = "tfstate-rg"
}



variable "action_groups" {
  type        = any
  description = "Configuration for monitoring action groups."
  default     = {}
}

variable "log_alert_rules" {
  type        = any
  description = "Configuration for log-based alert rules."
  default     = {}
}