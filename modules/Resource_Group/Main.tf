variable "rgs"{}
variable "location" {}

resource "azurerm_resource_group" "rg" {
  name     = var.rgs
  location = var.rgs
}
