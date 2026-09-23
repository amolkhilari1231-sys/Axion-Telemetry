data "azurerm_subnet" "AzureBastion_subnet" {
    for_each = var.AzureBastion
  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.rg_name
}


resource "azurerm_public_ip" "AzureBastion_pip" {
    for_each = var.AzureBastion
  name                = each.value.name
  resource_group_name = each.value.rg_name
  location            = each.value.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "Axion_Bastion" {
    depends_on = [ azurerm_public_ip.AzureBastion_pip ]
    for_each = var.AzureBastion 
  name                = each.value.name
  resource_group_name = each.value.rg_name
  location            = each.value.location

  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.AzureBastion_subnet[each.key].id
    public_ip_address_id = azurerm_public_ip.AzureBastion_pip[each.key].id
  }
}