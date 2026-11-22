variable "subnets" {}
variable "rgs" {}

resource "azurerm_subnet" "subnet" {
<<<<<<< HEAD
    for_each = var.subnets
    name = each.value.name
    resource_group_name = var.rgs
    virtual_network_name = each.value.vnet_name
    address_prefixes = each.value.address_prefixes
=======
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = each.value.rg_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
>>>>>>> f0aee43 ( Update deployment code)
}