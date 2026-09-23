data "azurerm_virtual_network" "vnet_id" {
    for_each = var.vnetpeering
  name                = each.value.vnet_name
  resource_group_name = each.value.rg_name
  
}
resource "azurerm_virtual_network_peering" "vnetpeering" {
    for_each = var.vnetpeering

  name                      = each.value.name
  resource_group_name       = each.value.rg_name
  virtual_network_name      = each.value.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet_id[each.key].id
}