<<<<<<< HEAD
variable "rgs"{}
variable "location" {}

resource "azurerm_resource_group" "rg" {
  name     = var.rgs
  location = var.rgs
=======
variable "rgs" {}

resource "azurerm_resource_group" "rg" {
  for_each = var.rgs
  name     = each.value.name
  location = each.value.location
>>>>>>> f0aee43 ( Update deployment code)
}
