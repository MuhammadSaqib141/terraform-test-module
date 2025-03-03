include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/network"
}

locals {
  read_region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.read_region.locals.region
  parent_dir = get_parent_terragrunt_dir()

}


inputs = {
  resource_group_name = "Saqib-RG"
  resource_group_location = local.region
  parent_dir = local.parent_dir
}


# exclude {
#   if = true
#   actions = ["plan", "apply"]
#   exclude_dependencies = true
# }