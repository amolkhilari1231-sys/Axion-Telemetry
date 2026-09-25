# variable "azure_firewall"{}
# data "azurerm_subnet" "subnet" {
#     for_each = var.azure_firewall
#   name                 = each.value.subnet_name
#   virtual_network_name = each.value.vnet_name
#   resource_group_name  = each.value.rg_name
# }


# resource "azurerm_public_ip" "firewall_pip" {
#     for_each = var.azure_firewall
#   name                = each.value.public_ip_name
#   location            = each.value.location
#   resource_group_name = each.value.rg_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_firewall" "azurefirewall" {
#     for_each = var.azure_firewall
#   name                = each.value.name
#   location            = each.value.location
#   resource_group_name = each.value.rg_name
#   sku_name            = each.value.sku_name
#   sku_tier            = each.value.sku_tier

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = data.azurerm_subnet.subnet[each.key].id
#     public_ip_address_id = azurerm_public_ip.firewall_pip[each.key].id
   
#   }
# }