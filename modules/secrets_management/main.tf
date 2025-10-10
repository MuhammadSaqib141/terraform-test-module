resource "azurerm_key_vault_secret" "secrets" {
  for_each = { for k, v in var.secrets : k => v } # k is the non-sensitive key

  name         = each.value.name
  value        = each.value.value
  key_vault_id = each.value.key_vault_id

  content_type    = try(each.value.content_type, "text/plain")
  expiration_date = try(each.value.expiration_date, null)
  not_before_date = try(each.value.not_before_date, null)
  tags            = try(each.value.tags, var.tags)

  lifecycle {
    ignore_changes = [value]
  }
}
