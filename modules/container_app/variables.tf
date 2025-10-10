variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group in which all resources will be deployed."
}

variable "org_prefix" {
  type        = string
  description = "A short prefix representing the organization or project name, used to standardize Azure resource names (e.g., 'ordertracking')."
}

variable "environment" {
  type        = string
  description = "The target environment for deployment, such as 'dev', 'test', 'stage', or 'prod'."
}

variable "name" {
  type        = string
  description = "The base name of the deployment or workload (e.g., 'ordertracking'). Used in resource naming."
}

variable "location" {
  type        = string
  description = "The Azure region where the Container App Environment and related resources will be created (e.g., 'eastus', 'westeurope')."
}

variable "tags" {
  type        = map(string)
  description = "A map of key-value pairs of tags to apply to all deployed Azure resources for cost management, governance, and organization."
  default     = {}
}

variable "user_assigned_identity_id" {
  type        = string
  description = "The resource ID of a User Assigned Managed Identity that will be attached to the Container App for secure authentication."
}

variable "registry_server" {
  type        = string
  description = "The login server of the container registry (e.g., 'myregistry.azurecr.io') where application images are stored."
}

variable "container_app_environment_id" {
  type        = string
  description = "The resource ID of the Azure Container App Environment in which the Container App will be deployed."
}

variable "container_app" {
  type        = any
  description = "Configuration block defining properties of the Container App (e.g., image, resources, scaling, secrets)."
  default     = {}
}
