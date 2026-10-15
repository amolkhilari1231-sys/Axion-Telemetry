data "azurerm_subnet" "frontend" {
    for_each = var.nat_gatway
  name                 = each.value.frontend.name
  virtual_network_name = each.value.frontend.virtual_network_name
  resource_group_name  = var.rgs
}

data "azurerm_subnet" "backend" {
    for_each = var.nat_gatway
  name                 = each.value.backend.name
  virtual_network_name = each.value.backend.virtual_network_name
  resource_group_name  = var.rgs
}

resource "azurerm_public_ip" "NAT_gateway_pip" {
    for_each = var.nat_gatway
  name                = each.value.public_ip_name
  location            = var.location
  resource_group_name = var.rgs
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = ["1"]
}

resource "azurerm_nat_gateway" "nat_gateway" {
    for_each = var.nat_gatway
  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.rgs
  sku_name                = "Standard"
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
}

resource "azurerm_subnet_nat_gateway_association" "frontend" {
    depends_on = [azurerm_nat_gateway.nat_gateway]
  for_each = var.nat_gatway

  subnet_id = data.azurerm_subnet.frontend[each.key].id

  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.key].id
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway" {
  for_each = var.nat_gatway

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[each.key].id
  public_ip_address_id = azurerm_public_ip.NAT_gateway_pip[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "backend" {
    depends_on = [ azurerm_nat_gateway.nat_gateway ]
  for_each = var.nat_gatway

  subnet_id = data.azurerm_subnet.backend[each.key].id

  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.key].id
}