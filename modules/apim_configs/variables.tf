variable "org_prefix" {}
variable "environment" {}
variable "resource_group_name" {}
variable "api_management_name" {}

variable "tags" { type = map(string) }

variable "app_name" { type = string }
variable "apim_configs" {
  type = any
}

variable "search_service_endpoint" {
  type        = string
  description = "The endpoint of the Azure AI Search service."
  default     = null # Make it optional
}

variable "search_index_name" {
  type        = string
  description = "The name of the search index to query."
  default     = null # Make it optional
}

variable "search_api_version" {
  type        = string
  description = "The API version for the search service."
  default     = "2023-11-01" # Default to a recent version
}

variable "ai_search_query_secret_id" {
  type        = string
  description = "Key Vault secret id for the AI Search query key"
}


variable "ai_search_named_value" {
  type        = string
  description = "The name of the APIM Named Value that holds the AI Search query key. This is used in the policy template."
  default     = null
}
