data "azurerm_virtual_network" "vnet_id" {
      for_each = {
    for k, v in var.vnetpeering :
    v.vnet_name => v
  }
  name                = each.value.vnet_name
  resource_group_name = each.value.rg_name
  
}
resource "azurerm_virtual_network_peering" "vnetpeering" {
    for_each = var.vnetpeering

  name                      = each.value.name
  resource_group_name       = each.value.rg_name
  virtual_network_name      = each.value.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet_id[each.value.remote_vnet_name].id

   allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}