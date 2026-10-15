rgs      = "Prod_rg"
location = "central india"

vnets = {
  vnet1 = {
    name          = "Spoke_vnet"
    address_space = ["10.10.0.0/16"]
  }

}
subnets = {
  subnet1 = {
    name             = "Frontend_subnet"
    vnet_name        = "Spoke_vnet"
    address_prefixes = ["10.0.1.0/24"]
  }
  subnet2 = {
    name             = "Backend_subnet"
    vnet_name        = "Spoke_vnet"
    address_prefixes = ["10.0.2.0/24"]
  }
  subnet3 = {
    name             = "database_subnet"
    vnet_name        = "Spoke_vnet"
    address_prefixes = ["10.0.3.0/24"]
  }
}
vms = {
  vm1 = {
    nic_name       = "frontend_nic"
    subnet_name    = "Frontend_subnet"
    vnet_name      = "Spoke_vnet"
    vm_name        = "axionfrontendvm"
    size           = "Standard_D4_v5"
    admin_username = "adminuser"
    admin_password = "Admin@123"
    nsg_name       = "frontend_nsg"

    security_rule = {
      allow_ssh = {
        name                       = "allow-SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }

    }
  }

  vm2 = {
    nic_name       = "backend_nic"
    subnet_name    = "Backend_subnet"
    vnet_name      = "Spoke_vnet"
    vm_name        = "axionbackendvm"
    size           = "Standard_D4_v5"
    admin_username = "adminuser"
    admin_password = "Admin@123"
    nsg_name       = "backend_nsg"

    security_rule = {

      allow_http = {
        name                       = "allow-http"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8001"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"

      }


    }
  }
}

vnetpeering = {
  peering1 = {
    name             = "peer1to2"
    vnet_name        = "Spoke_vnet"
    remote_vnet_name = "Hub_vnet"
  }
  peering2 = {
    name             = "peer2to1"
    vnet_name        = "Hub_vnet"
    remote_vnet_name = "Spoke_vnet"
  }
}

