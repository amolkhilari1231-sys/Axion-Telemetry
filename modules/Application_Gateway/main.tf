data "azurerm_subnet" "AppGateway_subnet" {
  for_each = var.Application_Gateway

  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.rg_name
}

resource "azurerm_public_ip" "Application_pip" {
  for_each = var.Application_Gateway

  name                = each.value.pip_names
  resource_group_name = each.value.rg_name
  location            = each.value.location

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_application_gateway" "Axion" {
  for_each = var.Application_Gateway

  name                = each.value.name
  resource_group_name = each.value.rg_name
  location            = each.value.location

  sku {
    name     = each.value.sku_name
    tier     = each.value.sku_tier
    capacity = each.value.sku_capacity
  }

  gateway_ip_configuration {
    name      = each.value.gateway_ip_config
    subnet_id = data.azurerm_subnet.AppGateway_subnet[each.key].id
  }

  frontend_port {
    name = each.value.frontend_port_name
    port = each.value.frontend_port
  }

  frontend_ip_configuration {
    name                 = each.value.frontend_ip_config
    public_ip_address_id = azurerm_public_ip.Application_pip[each.key].id
  }

  backend_address_pool {
    name  = each.value.backend_address_pool
    ip_addresses = [
      each.value.backend_private_ip
    ]
  }

  backend_http_settings {
    name                  = each.value.http_setting_name
    cookie_based_affinity = each.value.cookie_based_affinity
    port                  = each.value.port
    protocol              = each.value.protocol
    request_timeout       = each.value.request_timeout
  }

  http_listener {
    name                           = each.value.listener_name
    frontend_ip_configuration_name = each.value.frontend_ip_config
    frontend_port_name             = each.value.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = each.value.routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = each.value.listener_name
    backend_address_pool_name  = each.value.backend_address_pool
    backend_http_settings_name = each.value.http_setting_name
  }
}