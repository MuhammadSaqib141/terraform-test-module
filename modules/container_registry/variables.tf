variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure Container Registry (ACR) resource names."
}

variable "environment" {
  type        = string
  description = "The target deployment environment, such as 'dev', 'test', 'stage', or 'prod'."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Container Registry will be deployed."
}

variable "location" {
  type        = string
  description = "The Azure region where the Container Registry will be created (e.g., 'eastus', 'westeurope')."
}

variable "name" {
  type        = any
  description = "The base name for the Container Registry resource. Used to construct the registry's name (e.g., 'ordertrackingacr')."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value tags to assign to the Azure Container Registry for governance, cost management, and organization."
  default     = {}
}

variable "container_registry" {
  type        = any
  description = "A configuration object defining properties of the Azure Container Registry (e.g., SKU, admin enablement, network rules)."
}
