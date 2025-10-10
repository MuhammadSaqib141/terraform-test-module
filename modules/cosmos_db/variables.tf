variable "name" {
  type        = string
  description = "The base name of the resource or service being deployed. Used to construct resource names consistently."
}

variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure resource names."
}

variable "environment" {
  type        = string
  description = "The target deployment environment, such as 'dev', 'test', 'stage', or 'prod'."
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed (e.g., 'eastus', 'westeurope')."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group in which the resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to assign to all resources for cost tracking, governance, and organization."
}

variable "cosmosdb_account" {
  description = "Configuration object for the Cosmos DB Account."
  type        = any
}





