variable "org_prefix" {
  type        = string
  description = "Organization prefix for naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "Storage account base name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

variable "storage_config" {
  description = "Storage account configuration"
  type = object({
    account_tier                    = string
    account_replication_type        = string
    account_kind                    = optional(string, "StorageV2")
    min_tls_version                 = optional(string, "TLS1_2")
    https_traffic_only_enabled      = optional(bool, true)
    allow_nested_items_to_be_public = optional(bool, false)

    blob_properties = optional(object({
      versioning_enabled       = optional(bool, false)
      change_feed_enabled      = optional(bool, false)
      last_access_time_enabled = optional(bool, false)
      delete_retention_policy = optional(object({
        days = number
      }))
    }))
  })
}