variable "name" {
  type        = string
  description = "The unique name of the Dapr component (e.g., 'messagebus', 'statestore'). Used when referencing the component inside Container Apps."
}

variable "container_app_environment_id" {
  type        = string
  description = "The resource ID of the Azure Container App Environment (CAE) where this Dapr component will be registered."
}

variable "type" {
  type        = string
  description = "The Dapr component type that defines the underlying resource (e.g., 'pubsub.azure.eventhubs', 'state.azure.cosmosdb')."
}

variable "dapr_version" {
  type        = string
  description = "The Dapr API version of the component (typically 'v1')."
  default     = "v1"
}

variable "scopes" {
  type        = list(string)
  description = "List of Container App names that are allowed to access this component. If empty, the component is accessible by all apps in the environment."
  default     = []
}

variable "metadata" {
  type = list(object({
    name       = string
    value      = optional(string)
    secretName = optional(string)
  }))
  description = <<EOT
A list of metadata items for the Dapr component.  
Each item can define:
- `name`       : Metadata key.  
- `value`      : Value for the metadata (plain text).  
- `secretName` : Reference to a secret for secure values.  
EOT
  default     = []
}

variable "secrets" {
  type        = map(string)
  description = "A map of secrets for the Dapr component. Keys are secret names, values are the secret values. Marked sensitive for security."
  default     = {}
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value tags to apply to the Dapr component resource for governance and cost tracking."
  default     = {}
}
