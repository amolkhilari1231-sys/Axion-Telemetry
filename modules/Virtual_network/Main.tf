variable "vnets" {}
variable "rgs" {}
variable "location" {}

resource "azurerm_virtual_network" "vnet" {
    for_each = var.vnets
    name = each.value.name
    resource_group_name = var.rgs
    location = var.location
    address_space = each.value.address_space
  
}