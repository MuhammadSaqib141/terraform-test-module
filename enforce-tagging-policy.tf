resource "azurerm_policy_definition" "require_tags" {
  name         = "${var.org_prefix}-require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory tags on all resources"
  policy_rule  = <<POLICY_RULE
{
  "if": {
    "anyOf": [
      { "field": "tags['owner']", "exists": "false" },
      { "field": "tags['environment']", "exists": "false" },
      { "field": "tags['cost-center']", "exists": "false" },
      { "field": "tags['app']", "exists": "false" },
      { "field": "tags['data-classification']", "exists": "false" },
      { "field": "tags['support-contact']", "exists": "false" }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

resource "azurerm_resource_group_policy_assignment" "enforce_tagging_on_rgs" {
  for_each             = var.resource_groups
  name                 = "Enforce-Tags-${each.key}"
  resource_group_id    = module.resource_groups[each.key].id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "Enforce Mandatory Tags on ${each.key} RG"
}
