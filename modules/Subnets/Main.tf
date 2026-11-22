variable "subnets" {}
variable "rgs" {}

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = var.rgs
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
}
