# ./modules/search_configuration/variables.tf

variable "search_endpoint" {
  type        = string
  description = "The endpoint URL of the Azure AI Search service (e.g., https://<name>.search.windows.net)."
}

variable "search_admin_key" {
  type        = string
  sensitive   = true
  description = "The admin API key for the Azure AI Search service."
}

variable "search_setup" {
  type = object({
    datasource = object({
      name                      = string
      type                      = string
      credentials               = map(string)
      container                 = any
      dataChangeDetectionPolicy = optional(any)
    })
    index = object({
      name       = string
      fields     = list(any)
      suggesters = optional(list(any), [])
      # You can extend this with other index properties like:
      # scoringProfiles = optional(list(any), [])
      # analyzers       = optional(list(any), [])
    })
    indexer = object({
      name     = string
      schedule = optional(string, "PT5M") # Defaults to 5 minutes
    })
  })
  description = "A complete configuration object defining the datasource, index, and indexer for a single search setup."
}