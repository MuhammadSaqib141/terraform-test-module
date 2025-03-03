# -------------------- Generate `backend.tf` --------------------

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "Nouman-RG"
    storage_account_name = "tfstaccfinz"
    container_name       = "terragrunt-saqib"
    key                 = "${path_relative_to_include()}/tofu.tfstate"
  }
}
EOF
}

# -------------------- Generate `provider.tf` --------------------

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF
}


terraform {
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]

    required_var_files = ["auto.tfvars"]
  }
}

locals {
  read_region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  location        = local.read_region.locals.region

  read_environment = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment     = local.read_environment.locals.env
}

