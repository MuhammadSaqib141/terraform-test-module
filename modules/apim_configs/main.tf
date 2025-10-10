resource "azurerm_api_management_api" "this" {
  name                = var.apim_configs.api.name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name

  revision              = var.apim_configs.api.revision
  display_name          = var.apim_configs.api.display_name
  path                  = var.apim_configs.api.path
  protocols             = var.apim_configs.api.protocols
  api_type              = try(var.apim_configs.api.api_type, "http")
  description           = try(var.apim_configs.api.description, null)
  service_url           = try(var.apim_configs.api.service_url, null)
  subscription_required = try(var.apim_configs.api.subscription_required, true)
  version               = try(var.apim_configs.api.version, null)
  version_set_id        = try(var.apim_configs.api.version_set_id, null)
  revision_description  = try(var.apim_configs.api.revision_description, null)
  version_description   = try(var.apim_configs.api.version_description, null)
  source_api_id         = try(var.apim_configs.api.source_api_id, null)
  terms_of_service_url  = try(var.apim_configs.api.terms_of_service_url, null)

  dynamic "contact" {
    for_each = var.apim_configs.api.contact == null ? [] : [var.apim_configs.api.contact]
    content {
      email = try(contact.value.email, null)
      name  = try(contact.value.name, null)
      url   = try(contact.value.url, null)
    }
  }

  dynamic "license" {
    for_each = var.apim_configs.api.license == null ? [] : [var.apim_configs.api.license]
    content {
      name = try(license.value.name, null)
      url  = try(license.value.url, null)
    }
  }

  dynamic "import" {
    for_each = var.apim_configs.api.import == null ? [] : [var.apim_configs.api.import]
    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value

      dynamic "wsdl_selector" {
        for_each = try([import.value.wsdl_selector], [])
        content {
          service_name  = wsdl_selector.value.service_name
          endpoint_name = wsdl_selector.value.endpoint_name
        }
      }
    }
  }

  dynamic "oauth2_authorization" {
    for_each = var.apim_configs.api.oauth2_authorization == null ? [] : [var.apim_configs.api.oauth2_authorization]
    content {
      authorization_server_name = oauth2_authorization.value.authorization_server_name
      scope                     = try(oauth2_authorization.value.scope, null)
    }
  }

  dynamic "openid_authentication" {
    for_each = var.apim_configs.api.openid_authentication == null ? [] : [var.apim_configs.api.openid_authentication]
    content {
      openid_provider_name         = openid_authentication.value.openid_provider_name
      bearer_token_sending_methods = try(openid_authentication.value.bearer_token_sending_methods, null)
    }
  }

  dynamic "subscription_key_parameter_names" {
    for_each = var.apim_configs.api.subscription_key_parameter_names == null ? [] : [var.apim_configs.api.subscription_key_parameter_names]
    content {
      header = subscription_key_parameter_names.value.header
      query  = subscription_key_parameter_names.value.query
    }
  }
}

resource "azurerm_api_management_api_operation" "operations" {
  for_each            = { for op in var.apim_configs.operations : op.operation_id => op }
  operation_id        = each.value.operation_id
  api_name            = azurerm_api_management_api.this.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  display_name = each.value.display_name
  method       = each.value.method
  url_template = each.value.url_template
  description  = try(each.value.description, null)

  # ============================================================
  # Request
  # ============================================================
  dynamic "request" {
    for_each = each.value.request == null ? [] : [each.value.request]
    content {
      description = try(request.value.description, null)

      dynamic "header" {
        for_each = try(request.value.header, [])
        content {
          name          = header.value.name
          required      = header.value.required
          type          = header.value.type
          description   = try(header.value.description, null)
          default_value = try(header.value.default_value, null)
          values        = try(header.value.values, null)
          schema_id     = try(header.value.schema_id, null)
          type_name     = try(header.value.type_name, null)

          dynamic "example" {
            for_each = try(header.value.example, [])
            content {
              name           = example.value.name
              summary        = try(example.value.summary, null)
              description    = try(example.value.description, null)
              value          = try(example.value.value, null)
              external_value = try(example.value.external_value, null)
            }
          }
        }
      }

      dynamic "query_parameter" {
        for_each = try(request.value.query_parameter, [])
        content {
          name          = query_parameter.value.name
          required      = query_parameter.value.required
          type          = query_parameter.value.type
          description   = try(query_parameter.value.description, null)
          default_value = try(query_parameter.value.default_value, null)
          values        = try(query_parameter.value.values, null)
          schema_id     = try(query_parameter.value.schema_id, null)
          type_name     = try(query_parameter.value.type_name, null)

          dynamic "example" {
            for_each = try(query_parameter.value.example, [])
            content {
              name           = example.value.name
              summary        = try(example.value.summary, null)
              description    = try(example.value.description, null)
              value          = try(example.value.value, null)
              external_value = try(example.value.external_value, null)
            }
          }
        }
      }

      dynamic "representation" {
        for_each = try(request.value.representation, [])
        content {
          content_type = representation.value.content_type
          schema_id    = try(representation.value.schema_id, null)
          type_name    = try(representation.value.type_name, null)

          dynamic "example" {
            for_each = try(representation.value.example, [])
            content {
              name           = example.value.name
              summary        = try(example.value.summary, null)
              description    = try(example.value.description, null)
              value          = try(example.value.value, null)
              external_value = try(example.value.external_value, null)
            }
          }

          dynamic "form_parameter" {
            for_each = try(representation.value.form_parameter, [])
            content {
              name          = form_parameter.value.name
              required      = form_parameter.value.required
              type          = form_parameter.value.type
              description   = try(form_parameter.value.description, null)
              default_value = try(form_parameter.value.default_value, null)
              values        = try(form_parameter.value.values, null)
              schema_id     = try(form_parameter.value.schema_id, null)
              type_name     = try(form_parameter.value.type_name, null)

              dynamic "example" {
                for_each = try(form_parameter.value.example, [])
                content {
                  name           = example.value.name
                  summary        = try(example.value.summary, null)
                  description    = try(example.value.description, null)
                  value          = try(example.value.value, null)
                  external_value = try(example.value.external_value, null)
                }
              }
            }
          }
        }
      }
    }
  }

  # ============================================================
  # Response
  # ============================================================
  dynamic "response" {
    for_each = each.value.response != null ? each.value.response : []
    content {
      status_code = response.value.status_code
      description = try(response.value.description, null)

      dynamic "header" {
        for_each = try(response.value.header, [])
        content {
          name          = header.value.name
          required      = header.value.required
          type          = header.value.type
          description   = try(header.value.description, null)
          default_value = try(header.value.default_value, null)
          values        = try(header.value.values, null)
          schema_id     = try(header.value.schema_id, null)
          type_name     = try(header.value.type_name, null)

          dynamic "example" {
            for_each = try(header.value.example, [])
            content {
              name           = example.value.name
              summary        = try(example.value.summary, null)
              description    = try(example.value.description, null)
              value          = try(example.value.value, null)
              external_value = try(example.value.external_value, null)
            }
          }
        }
      }

      dynamic "representation" {
        for_each = try(response.value.representation, [])
        content {
          content_type = representation.value.content_type
          schema_id    = try(representation.value.schema_id, null)
          type_name    = try(representation.value.type_name, null)

          dynamic "example" {
            for_each = try(representation.value.example, [])
            content {
              name           = example.value.name
              summary        = try(example.value.summary, null)
              description    = try(example.value.description, null)
              value          = try(example.value.value, null)
              external_value = try(example.value.external_value, null)
            }
          }

          dynamic "form_parameter" {
            for_each = try(representation.value.form_parameter, [])
            content {
              name          = form_parameter.value.name
              required      = form_parameter.value.required
              type          = form_parameter.value.type
              description   = try(form_parameter.value.description, null)
              default_value = try(form_parameter.value.default_value, null)
              values        = try(form_parameter.value.values, null)
              schema_id     = try(form_parameter.value.schema_id, null)
              type_name     = try(form_parameter.value.type_name, null)

              dynamic "example" {
                for_each = try(form_parameter.value.example, [])
                content {
                  name           = example.value.name
                  summary        = try(example.value.summary, null)
                  description    = try(example.value.description, null)
                  value          = try(example.value.value, null)
                  external_value = try(example.value.external_value, null)
                }
              }
            }
          }
        }
      }
    }
  }

  # ============================================================
  # Template Parameters
  # ============================================================
  dynamic "template_parameter" {
    for_each = each.value.template_parameter != null ? each.value.template_parameter : []
    content {
      name          = template_parameter.value.name
      required      = template_parameter.value.required
      type          = template_parameter.value.type
      description   = try(template_parameter.value.description, null)
      default_value = try(template_parameter.value.default_value, null)
      values        = try(template_parameter.value.values, null)
      schema_id     = try(template_parameter.value.schema_id, null)
      type_name     = try(template_parameter.value.type_name, null)

      dynamic "example" {
        for_each = try(template_parameter.value.example, [])
        content {
          name           = example.value.name
          summary        = try(example.value.summary, null)
          description    = try(example.value.description, null)
          value          = try(example.value.value, null)
          external_value = try(example.value.external_value, null)
        }
      }
    }
  }
}

resource "azurerm_api_management_api_policy" "policy" {
  count               = var.apim_configs.policy_file != null ? 1 : 0
  api_name            = azurerm_api_management_api.this.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = templatefile("${path.module}/Policies/${var.apim_configs.policy_file}", {
    search_service_endpoint = var.search_service_endpoint
    search_index_name       = var.search_index_name
    search_api_version      = var.search_api_version
    ai_search_named_value   = azurerm_api_management_named_value.ai_search_query_secret.name
    jwt_audiences           = var.apim_configs.jwt_audiences
    jwt_issuers             = var.apim_configs.jwt_issuers

    cors_allow_credentials = var.apim_configs.cors.allow_credentials
    cors_allowed_origins   = var.apim_configs.cors.allowed_origins
    cors_allowed_methods   = var.apim_configs.cors.allowed_methods
    cors_allowed_headers   = var.apim_configs.cors.allowed_headers
    cors_expose_headers    = var.apim_configs.cors.expose_headers
    cors_preflight_max_age = var.apim_configs.cors.preflight_max_age

    rate_limit_calls  = var.apim_configs.rate_limit.calls
    rate_limit_period = var.apim_configs.rate_limit.renewal_period
  })

}

resource "azurerm_api_management_named_value" "ai_search_query_secret" {
  name                = "${replace(var.app_name, "_", "-")}-ai-search-query-key"
  display_name        = "${replace(var.app_name, "_", "-")}-ai-search-query-key"
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  secret              = true

  value_from_key_vault {
    secret_id = var.ai_search_query_secret_id
  }

}

resource "azurerm_api_management_subscription" "api_subscription" {
  count = var.apim_configs != null && var.apim_configs.api.subscription_required ? 1 : 0

  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  state               = "active"
  display_name        = "${azurerm_api_management_api.this.name}-API-Sub"
  api_id              = azurerm_api_management_api.this.id
  allow_tracing       = false

  # lifecycle {
  #   ignore_changes = [ api_id ]
  # }
}
