variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization name, used for naming Azure resources consistently."
}

variable "environment" {
  type        = string
  description = "Specifies the deployment environment (e.g., dev, test, stage, prod) for resource organization."
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed (e.g., eastus, westeurope)."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources for cost tracking, organization, and governance."
}

variable "name" {
  type        = string
  description = "The base name for the resource or service being deployed."
}

variable "user_assigned_identity_resource_ids" {
  type        = list(string)
  default     = []
  description = "A list of User Assigned Managed Identity resource IDs to associate with resources for authentication."
}

variable "api_management_service" {
  type        = any
  description = "A map defining API Management service configurations (e.g., name, SKU, publisher details)."
  default     = {}
}
