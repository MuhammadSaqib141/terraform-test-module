# -------------------- Variables --------------------

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
}

variable "resource_group_location" {
  description = "The Azure region for resource deployment"
  type        = string
}

variable "network_interfaces" {
  description = "List of network interfaces to be created"
  type = list(object({
    name         = string
    subnet_id    = string
    has_public_ip = bool
  }))
}

variable "linux_vms" {
  description = "List of Linux virtual machines with configurations."
  type = list(object({
    name                           = string
    size                           = string
    admin_username                 = string
    admin_password                 = string
    disable_password_authentication = bool
    network_interface_names        = list(string)
    os_disk_caching                = string
    os_disk_storage_account_type   = string
    source_image_reference         = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  }))
}