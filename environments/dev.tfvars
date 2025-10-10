# =============================================================================
# CORE ENVIRONMENT SETTINGS
# =============================================================================
environment = "dev"
org_prefix  = "ordertracking"
location    = "westus2"
# =============================================================================
# COMMON TAGS - Applied to all resources created in this environment.
# =============================================================================
common_tags = {
  owner               = "DevTeam"
  cost-center         = "1234-DEV"
  support-contact     = "dev.support@example.com"
  data-classification = "Confidential"
}

# =============================================================================
# ADMIN ACCESS CONTROL
# =============================================================================
# Your personal Azure AD User Object ID for granting initial admin access.
# admin_user_object_id = "xxx-xxx-xxxxx-xxx-xxxxx"

# =============================================================================
# SHARED INFRASTRUCTURE COMPONENTS
# Defined once, used by multiple applications.
# =============================================================================

resource_groups = {
  infra = {}
  apps  = {}
}

resource_group_infra = "infra"
resource_group_app   = "apps"


# =============================================================================
# DYNAMIC NETWORK CONFIGURATION
# =============================================================================
virtual_networks = {
  main = {
    address_space = ["172.16.0.0/16"]

    subnets = {
      "cae-subnet" = {
        address_prefixes = ["172.16.0.0/23"]
      },

      "pe-subnet" = {
        address_prefixes = ["172.16.2.0/24"]

        network_security_group = {
          rules = [
            {
              name                       = "Allow-CAE-Subnet-To-ACR"
              priority                   = 100
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "443"
              source_address_prefix      = "172.16.0.0/23" 
              destination_address_prefix = "*"
            },
            {
              name                       = "Allow-ADO-Agent-VNet-To-ACR"
              priority                   = 110
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "443"
              source_address_prefix      = "10.0.0.0/16" # Yeh ADO Agent VNet ka CIDR hai
              destination_address_prefix = "*"
            }
          ]
        }
      }
    }
  }
}

log_analytics_workspaces = {
  main = {
    name              = "main"
    sku               = "PerGB2018"
    retention_in_days = 30
    daily_quota_gb    = 1 # Keep a low cap for dev to control costs
  }
}

container_registries = {
  main = {
    sku                           = "Premium" #"Basic" #"Premium"
    public_network_access_enabled = false
  }
}

# Search service configuration
search_services = {
  main = {
    sku             = "free" # Use free tier for dev
    partition_count = 1
    replica_count   = 1

    identity = {
      type = "SystemAssigned"
    }
  }
}



api_management_services = {
  # A single APIM instance for the environment
  main = {
    publisher_name           = "Order Tracking Dev Team"
    publisher_email          = "dev.admins@example.com"
    sku_name                 = "Developer_1"
    system_assigned_identity = true
  }
}

front_doors = {
  # A single Front Door for the environment
  main = {
    sku_name = "Premium_AzureFrontDoor"
    waf_policy = {
      enabled = true
      mode    = "Detection" # Use Detection mode in dev to log, not block.
    }
  }
}

# =============================================================================
# OBSERVABILITY & MONITORING  (<<< This is a top-level, environment-wide configuration)
# =============================================================================
action_groups = {
  "critical-alerts-ag" = {
    short_name = "critAlerts"
    email_receivers = [
      # {
      #   name          = "DevTeam"
      #   email_address = "dev.support@example.com"
      # },
      {
        name          = "Saqib"
        email_address = "muhammad.saqib@eurustechnologies.com"
      }
    ]
  }
}

log_alert_rules = {
  "apim-high-5xx-error-rate" = {
    description      = "Alert when the rate of APIM gateway requests with 5xx status codes exceeds 5%."
    query            = <<-QUERY
      ApiManagementGatewayLogs
      | summarize
          TotalRequests = count(),
          FailedRequests = countif(ResponseCode >= 400)
          by bin(TimeGenerated, 5m)
      | extend ErrorRate = (todouble(FailedRequests) * 100.0 / todouble(TotalRequests))
      | where ErrorRate > 5
    QUERY
    severity         = 1 # Critical
    frequency        = 5
    time_window      = 5
    threshold        = 0 # Trigger if any result row is returned
    operator         = "GreaterThan"
    action_group_key = "critical-alerts-ag"
  },
  "eventhub-throttled-requests" = {
    description      = "Alert when any Event Hubs namespace reports throttled requests (HTTP 429)."
    query            = <<-QUERY
      AzureDiagnostics
        | where ResourceProvider == "MICROSOFT.EVENTHUB"
        | where Category == "OperationalLogs"
        | where Status_s != "Succeeded" or EventName_s has_any ("ServerBusy", "QuotaExceeded", "Throttled", "Throttle", "429")
        | summarize ThrottledRequests = count() 
            by Resource, bin(TimeGenerated, 15m)
        | where ThrottledRequests > 5
        | order by TimeGenerated desc
    QUERY
    severity         = 2 # Error
    frequency        = 15
    time_window      = 15
    threshold        = 0
    operator         = "GreaterThan"
    action_group_key = "critical-alerts-ag"
  },
  "cosmosdb-high-429-rate" = {
    description      = "Alert when the number of throttled Cosmos DB requests (HTTP 429) is high."
    query            = <<-QUERY
      AzureDiagnostics
      | where ResourceProvider == "MICROSOFT.DOCUMENTDB" and Category == "DataPlaneRequests"
      | where statusCode_s == "429"
      | summarize ThrottledRequests = count() by bin(TimeGenerated, 5m)
      | where ThrottledRequests > 20
    QUERY
    severity         = 2 # Error
    frequency        = 5
    time_window      = 5
    threshold        = 0
    operator         = "GreaterThan"
    action_group_key = "critical-alerts-ag"
  }
}

# =============================================================================
# APPLICATION-SPECIFIC DEFINITIONS
# Each top-level key in this map represents a distinct application system.
# =============================================================================

applications = {

  # --- Definition for the 'Order Tracking' Application ---
  order_tracking = {
    # Each application gets its own Container App Environment
    container_app_environment = {
      log_analytics_workspace_key = null  # Connects to the shared LAW
      zone_redundancy_enabled     = false # Not required for dev
      infrastructure_subnet_id    = null  # No VNet integration for dev
    }

    # Each application gets its own Managed Identity for secure access
    managed_identity = {
    }

    # Each application gets its own dedicated Key Vault for its secrets
    key_vault = {
      sku_name                      = "standard"
      soft_delete_retention_days    = 7
      purge_protection_enabled      = false
      enable_rbac_authorization     = true
      public_network_access_enabled = true
    }
    # Temporary - for initial infrastructure setup
    container_apps = {
      order-api = {
        image_name = "order-api"
        # image_name   = "mcr.microsoft.com/azuredocs/containerapps-helloworld"
        image_tag    = "latest"
        cpu          = 0.25
        memory       = "0.5Gi"
        min_replicas = 1
        max_replicas = 3
        ingress = {
          enabled     = true
          target_port = 3000
          # target_port = 80
        }
      },

      order-worker = {
        image_name   = "order-worker"
        image_tag    = "latest"
        cpu          = 0.25
        memory       = "0.5Gi"
        min_replicas = 1
        max_replicas = 5
        ingress = {
          enabled = false
        }
      }
    }

    event_hub = {
      resource_group_key = "apps"
      sku                = "Standard"
      hub_name           = "orders"
      partition_count    = 2
      message_retention  = 1
      # can add the throughput Units  (Processing unit of event hub)
    }
    cosmos_db = {
      resource_group_key = "apps"
      kind               = "GlobalDocumentDB"
      sql_database = {
        database_name = "ordersdb"
      }
      sql_container = {
        name                = "orders"
        partition_key_paths = ["/id"] #["/customerId"]
        throughput          = 400
      }
    }
    search_setup = {
      datasource = {
        name = "orders-cosmos-datasource"
        type = "cosmosdb"
        container = {
          name  = "orders"
          query = "SELECT c.id, c[\"value\"].id AS orderId, c[\"value\"].customerId AS customerId, c[\"value\"].status AS status, c[\"value\"].createdAt AS createdAt, c[\"value\"].total AS total, c[\"value\"].items AS items, c[\"value\"].documentType AS documentType, c._ts AS _ts FROM c WHERE c._ts > @HighWaterMark"
        }
        dataChangeDetectionPolicy = {
          "@odata.type"           = "#Microsoft.Azure.Search.HighWaterMarkChangeDetectionPolicy"
          highWaterMarkColumnName = "_ts"
        }
      }
      index = {
        name = "orders-index"
        # The entire index schema is now defined with the application.
        fields = [
          { name = "id", type = "Edm.String", key = true, retrievable = true, searchable = false },
          { name = "orderId", type = "Edm.String", retrievable = true, searchable = true, filterable = true, sortable = true },
          { name = "customerId", type = "Edm.String", retrievable = true, searchable = true, filterable = true, facetable = true },
          { name = "status", type = "Edm.String", retrievable = true, searchable = true, filterable = true, facetable = true },
          { name = "createdAt", type = "Edm.String", retrievable = true, filterable = true, sortable = true },
          { name = "total", type = "Edm.Double", retrievable = true, filterable = true, sortable = true },
          { name = "items", type = "Collection(Edm.String)", retrievable = true, searchable = true },
          { name = "documentType", type = "Edm.String", retrievable = true, filterable = true }
        ]
        suggesters = [
          {
            name         = "sg"
            searchMode   = "analyzingInfixMatching"
            sourceFields = ["orderId", "customerId"]
          }
        ]
      }
      indexer = {
        name     = "orders-indexer"
        schedule = "PT5M" # Every 5 minutes
      }
    }
    apim_configs = {
      api = {
        name         = "order-search"
        display_name = "Order Search"
        path         = "orders"
        protocols    = ["https"]
        revision     = "1"
      }

      operations = [
        {
          operation_id = "search-order"
          display_name = "Search Order"
          method       = "GET"
          url_template = "/search"
          description  = "Search orders by query parameters"

          # request, response, template_parameter can be added later if needed
          request            = null
          response           = null
          template_parameter = null
        }
      ]

      policy_file = "api_policy.tpl"
      jwt_audiences = [
        "api://01cb876d-2289-4250-b4b7-bc4b85203948",
      ]

      jwt_issuers = [
        "https://sts.windows.net/81061c75-300e-4d0a-a517-23ed865d3866/",
      ]

      cors = {
        allow_credentials = "false"
        allowed_origins   = ["*"]
        allowed_methods   = ["GET", "POST", "OPTIONS"]
        allowed_headers   = ["*"]
        expose_headers    = ["*"]
        preflight_max_age = 300
      }

      rate_limit = {
        calls          = 100
        renewal_period = 60
      }
    }
  }
}
