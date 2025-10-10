# terraform {
#   backend "azurerm" {
#     use_oidc = true
#   }

#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~> 4.0"
#     }
#     time = { 
#       source  = "hashicorp/time"
#       version = ">= 0.9.1" 
#     }
#     azuread = {
#       source  = "hashicorp/azuread"
#       version = "~> 3.0"
#     }
#   }
# }


# File: provider.tf
terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" } # Add this
    time    = { source = "hashicorp/time", version = ">= 0.9.1" }
  }
}

provider "azurerm" {
  features {}

  # Force OIDC authentication
  # use_oidc = true
  # use_cli  = false
  # use_msi  = false
}

provider "azuread" {}