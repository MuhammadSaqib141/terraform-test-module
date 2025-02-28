variable "resource_group_name" {
  description = "The name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "account_tier" {
  description = "The tier of the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "The replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "blob_containers" {
  description = "List of Blob containers to create"
  type        = list(string)
  default     = []
}

variable "file_shares" {
  description = "List of File Shares to create"
  type        = list(string)
  default     = []
}
