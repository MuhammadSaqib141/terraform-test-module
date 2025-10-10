resource "azurerm_cdn_frontdoor_profile" "main" {
  for_each = var.front_doors

  name                = "${var.org_prefix}-${var.environment}-${each.key}-fd"
  resource_group_name = var.resource_group_name
  sku_name            = each.value.sku_name
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  for_each = { for k, v in var.front_doors : k => v if v.waf_policy.enabled == true }

  name                = "${title(replace(var.org_prefix, "-", ""))}${title(var.environment)}${title(each.key)}WAF" #"${replace(var.org_prefix, "-", "")}${var.environment}${each.key}waf"
  resource_group_name = var.resource_group_name
  sku_name            = each.value.sku_name
  mode                = each.value.waf_policy.mode
  tags                = var.tags

  dynamic "managed_rule" {
    for_each = each.value.sku_name == "Premium_AzureFrontDoor" ? [1] : []
    content {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      action  = "Block"
    }
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  for_each = azurerm_cdn_frontdoor_profile.main

  name                     = "${each.value.name}-endpoint"
  cdn_frontdoor_profile_id = each.value.id
  tags                     = each.value.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "apim_og" {
  for_each = azurerm_cdn_frontdoor_profile.main

  name                     = "${each.value.name}-og-apim"
  cdn_frontdoor_profile_id = each.value.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 2
  }

  health_probe {
    path                = "/status-0123456789abcdef"
    protocol            = "Https"
    request_type        = "HEAD"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "apim_backend" {
  for_each = azurerm_cdn_frontdoor_origin_group.apim_og

  name                           = "${each.value.name}-origin"
  cdn_frontdoor_origin_group_id  = each.value.id
  enabled                        = true
  host_name                      = var.apim_gateway_hostnames[each.key]
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.apim_gateway_hostnames[each.key]
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "default" {
  for_each = azurerm_cdn_frontdoor_endpoint.main

  name                          = "${each.value.name}-route-default"
  cdn_frontdoor_endpoint_id     = each.value.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim_og[each.key].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.apim_backend[each.key].id]

  enabled                = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true

}

resource "azurerm_cdn_frontdoor_security_policy" "waf_link" {
  for_each = { for k, v in azurerm_cdn_frontdoor_firewall_policy.waf : k => v }

  name                     = "${azurerm_cdn_frontdoor_endpoint.main[each.key].name}-secpolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[each.key].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = each.value.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main[each.key].id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

