# -------------------- Public IP --------------------

resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
}

# -------------------- Network Interfaces --------------------

resource "azurerm_network_interface" "nic" {
  for_each            = { for nic in var.network_interfaces : nic.name => nic } 

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.has_public_ip ? azurerm_public_ip.public_ip.id : null
  }
}

# -------------------- Linux Virtual Machines --------------------

resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each = { for vm in var.linux_vms : vm.name => vm }  

  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  location                          = var.resource_group_location
  size                              = each.value.size
  admin_username                    = each.value.admin_username
  admin_password                    = each.value.admin_password
  disable_password_authentication   = each.value.disable_password_authentication

  network_interface_ids = [for nic_name in each.value.network_interface_names : azurerm_network_interface.nic[nic_name].id]

  os_disk {
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }
}