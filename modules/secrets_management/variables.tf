variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    name            = string
    value           = string
    key_vault_id    = string
    content_type    = optional(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
    tags            = optional(map(string))
  }))
}


variable "tags" {
  type        = map(string)
  description = "Default tags for secrets"
  default     = {}
}
