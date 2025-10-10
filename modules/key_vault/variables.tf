variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure Key Vault resource names (e.g., 'ordertracking')."
}

variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., 'dev', 'test', 'stage', 'prod')."
}

variable "location" {
  type        = string
  description = "The Azure region where the Key Vault will be created (e.g., 'eastus', 'westeurope')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where the Key Vault will be deployed."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to apply to the Key Vault for governance, cost tracking, and organization."
  default     = {}
}

variable "name" {
  type        = string
  description = "The base name for the Key Vault resource. Used to construct the vault name."
}

variable "key_vault" {
  type        = any
  description = "A configuration object defining the Key Vault settings (e.g., SKU, access policies, network rules)."
  default     = {}
}
