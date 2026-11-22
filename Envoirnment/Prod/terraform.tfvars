<<<<<<< HEAD
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

=======
rgs = {
  rg1 = {
    name     = "prod_rg"
    location = "central india"
  }
}

vnets = {
  vnet1 = {
    name          = "Spoke_vnet_prod"
    rg_name       = "prod_rg"
    location      = "central india"
    address_space = ["10.10.0.0/16"]
  }
  vnet2 = {
    name          = "Hub_vnet_prod"
    rg_name       = "prod_rg"
    location      = "central india"
    address_space = ["10.11.0.0/16"]
  }
}

subnets = {
  subnet1 = {
    name             = "Frontend_subnet"
    rg_name          = "prod_rg"
    vnet_name        = "Spoke_vnet_prod"
    address_prefixes = ["10.10.1.0/24"]
  }
  subnet2 = {
    name             = "Backend_subnet"
    rg_name          = "prod_rg"
    vnet_name        = "Spoke_vnet_prod"
    address_prefixes = ["10.10.2.0/24"]
  }
  subnet3 = {
    name             = "AppGateway_subnet"
    rg_name          = "prod_rg"
    vnet_name        = "Hub_vnet_prod"
    address_prefixes = ["10.11.1.0/24"]
  }
  subnet5 = {
    name             = "AzureBastionSubnet"
    rg_name          = "prod_rg"
    vnet_name        = "Hub_vnet_prod"
    address_prefixes = ["10.11.3.0/24"]
  }
  subnet6 = {
    name             = "AzureFirewallSubnet"
    rg_name          = "prod_rg"
    vnet_name        = "Hub_vnet_prod"
    address_prefixes = ["10.11.4.0/24"]
  }
}

vms = {
  vm2 = {
    nic_name       = "backend_nic_prod"
    rg_name        = "prod_rg"
    location       = "central india"
    subnet_name    = "Backend_subnet"
    vnet_name      = "Spoke_vnet_prod"
    vm_name        = "axionbackendvm-prod"
    size           = "Standard_D4_v5"
    admin_username = "adminuser"
    admin_password = "Admin@123!"
    nsg_name       = "backend_nsg_prod"

    security_rule = {
>>>>>>> f0aee43 ( Update deployment code)
      allow_http = {
        name                       = "allow-http"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8001"
<<<<<<< HEAD
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"

      }


=======
        source_address_prefix      = "10.10.2.0/24"
        destination_address_prefix = "*"
      }
>>>>>>> f0aee43 ( Update deployment code)
    }
  }
}

<<<<<<< HEAD
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

=======
postgresql = {
  postgresql1 = {
    name           = "axionpostgresql-prod"
    rg_name        = "prod_rg"
    location       = "central india"
    admin_username = "adminuser"
    admin_password = "Admin@123!"
  }
}

AzureBastion = {
  bastion1 = {
    name        = "axionbastion-prod"
    rg_name     = "prod_rg"
    location    = "central india"
    subnet_name = "AzureBastionSubnet"
    vnet_name   = "Hub_vnet_prod"
    pip_name    = "bastion_pip_prod"
  }
}

vnetpeering = {
  peering1 = {
    name             = "peer1to2_prod"
    rg_name          = "prod_rg"
    vnet_name        = "Spoke_vnet_prod"
    remote_vnet_name = "Hub_vnet_prod"
  }
  peering2 = {
    name             = "peer2to1_prod"
    rg_name          = "prod_rg"
    vnet_name        = "Hub_vnet_prod"
    remote_vnet_name = "Spoke_vnet_prod"
  }
}

nat_gatway = {
  nat1 = {
    name                    = "nat-gateway-prod"
    rg_name                 = "prod_rg"
    location                = "central india"
    public_ip_name          = "nat-gateway-pip-prod"
    idle_timeout_in_minutes = 10
    zones                   = ["1"]

    frontend = {
      name                 = "Frontend_subnet"
      virtual_network_name = "Spoke_vnet_prod"
      resource_group_name  = "prod_rg"
    }
    backend = {
      name                 = "Backend_subnet"
      virtual_network_name = "Spoke_vnet_prod"
      resource_group_name  = "prod_rg"
    }
  }
}

Application_Gateway = {
  appgw1 = {
    name     = "Axion-appgateway-prod"
    rg_name  = "prod_rg"
    location = "central india"

    sku_name     = "Standard_v2"
    sku_tier     = "Standard_v2"
    sku_capacity = 2

    subnet_name = "AppGateway_subnet"
    vnet_name   = "Hub_vnet_prod"

    gateway_ip_config = "my-gateway-ip-configuration"

    frontend_port_name = "frontend-port"
    frontend_port      = 80

    frontend_ip_config = "frontend-ip-configuration"
    pip_names          = "Applicationpipname-prod"

    backend_address_pool = "backend-address-pool-name"
    backend_private_ip   = "10.10.1.4"

    http_setting_name     = "http-setting-name"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 8001
    protocol              = "Http"
    request_timeout       = 60

    listener_name     = "listener-name"
    routing_rule_name = "routing-rule-name"
  }
}
>>>>>>> f0aee43 ( Update deployment code)
