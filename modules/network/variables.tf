# -------------------- Variables --------------------

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "resource_group_location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "virtual_networks" {
  description = "List of virtual networks with names, locations, and address spaces"
  type        = list(object({
    name          = string
    address_space = list(string)
    location      = string
  }))
}

variable "subnets" {
  description = "List of subnets with names, address prefixes, and associated NSGs"
  type        = list(object({
    name                = string
    address_prefixes    = list(string)
    virtual_network_name = string
    nsg_to_be_associated = string
  }))
}

variable "nsgs" {
  description = "Network Security Groups with associated rules"
  type        = list(object({
    name  = string
    rules = map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}

