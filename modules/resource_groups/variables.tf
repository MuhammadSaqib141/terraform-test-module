variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure resource names."
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'test', 'stage', 'prod')."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed (e.g., 'eastus', 'westeurope')."
}

variable "name" {
  type        = string
  description = "The base name of the resource or service being deployed. Used to construct resource names consistently."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to apply to all resources for governance, cost tracking, and organization."
  default     = {}
}
