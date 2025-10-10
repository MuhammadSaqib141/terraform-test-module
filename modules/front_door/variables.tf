variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, applied to Azure resource names for standardization."
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'test', 'stage', 'prod')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Front Door and related resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to apply to all deployed resources for governance, cost tracking, and organization."
  default     = {}
}

variable "front_doors" {
  type        = any
  description = "A configuration object (or map of objects) defining one or more Azure Front Door instances, including routing rules, backends, and settings."
  default     = {}
}

variable "apim_gateway_hostnames" {
  type        = map(string)
  description = "A map of API Management (APIM) gateway hostnames to integrate with Azure Front Door (e.g., { 'dev' = 'dev.api.contoso.com', 'prod' = 'api.contoso.com' })."
}
