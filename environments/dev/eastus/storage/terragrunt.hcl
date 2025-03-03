include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/storage"
}

locals {
  read_region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.read_region.locals.region

  read_environment = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment     = local.read_environment.locals.env // it is "dev" for now
}

dependency "resource_group_name" {
  config_path = "../network"

  mock_outputs = {
    rg_name = "Saqib-RG"
  }
} 


dependency "resource_group_location" {
  config_path = "../network"

  mock_outputs = {
    rg_location = "eastus"
  }
} 

inputs = {
  location = dependency.resource_group_location.outputs.rg_location
  resource_group_name = dependency.resource_group_name.outputs.rg_name


}

# dependencies {
#   paths = ["../network"]
# }

# exclude {
#   if = local.environment == "dev"
#   actions = ["plan"]
#   exclude_dependencies = true
# }


# exclude {
#   if = true
#   actions = ["plan", "apply"]
#   exclude_dependencies = true
# }
