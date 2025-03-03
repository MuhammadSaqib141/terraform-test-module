

# Virtual Network Configuration
virtual_networks = [
  {
    name          = "vnet-eastus"
    address_space = ["10.0.0.0/16"]
    location      = "East US"
  }
]

# Subnet Configuration
subnets = [
  {
    name                 = "subnet-web"
    address_prefixes     = ["10.0.1.0/24"]
    virtual_network_name = "vnet-eastus"
    nsg_to_be_associated = "nsg-web"
  },
  {
    name                 = "subnet-db"
    address_prefixes     = ["10.0.2.0/24"]
    virtual_network_name = "vnet-eastus"
    nsg_to_be_associated = "nsg-db"
  }
]

# Network Security Groups (NSGs) and Rules
nsgs = [
  {
    name  = "nsg-web"
    rules = {
      "allow-http" = {
        name                       = "Allow-HTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      "allow-https" = {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  },
  {
    name  = "nsg-db"
    rules = {
      "allow-db" = {
        name                       = "Allow-DB"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"
      }
    }
  }
]
