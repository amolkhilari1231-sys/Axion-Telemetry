variable "vnets" {}
variable "rgs" {}
variable "location" {}

resource "azurerm_virtual_network" "vnet" {
<<<<<<< HEAD
    for_each = var.vnets
    name = each.value.name
    resource_group_name = var.rgs
    location = var.location
    address_space = each.value.address_space
  
=======
  for_each            = var.vnets
  name                = each.value.name
  resource_group_name = each.value.rg_name
  location            = each.value.location
  address_space       = each.value.address_space

>>>>>>> f0aee43 ( Update deployment code)
}