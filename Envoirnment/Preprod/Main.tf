module "resource_group" {
  source = "../../modules/Resource_Group"
  rgs    = var.rgs

}
module "virtual_network" {
  depends_on = [module.resource_group]
  source     = "../../modules/Virtual_network"
  vnets      = var.vnets
}
module "subnet" {
  depends_on = [module.virtual_network]
  source     = "../../modules/Subnets"
  subnets    = var.subnets
}
module "virtual_machine" {
  depends_on = [module.subnet]
  source     = "../../modules/Virtual_machine"
  vms        = var.vms
}

module "postgresql_flexble_service" {
  depends_on = [module.subnet]
  source     = "../../modules/postgresql_flexble_service"
  postgresql = var.postgresql
}

module "Azure_Bastion" {
  depends_on   = [module.subnet]
  source       = "../../modules/Azure_Bastion"
  AzureBastion = var.AzureBastion
}

module "vnet_peering" {
  depends_on  = [module.virtual_network]
  source      = "../../modules/VNet_Peering"
  vnetpeering = var.vnetpeering
}

module "nat_gateway" {
  depends_on = [module.subnet]
  source     = "../../modules/Nat_gateway"
  nat_gatway = var.nat_gatway
}

module "Application_Gateway" {
  depends_on          = [module.subnet, module.nat_gateway]
  source              = "../../modules/Application_Gateway"
  Application_Gateway = var.Application_Gateway
}

# module "Azure_firewall" {
#   depends_on     = [module.subnet, module.nat_gateway]
#   source         = "../../modules/Azure_firewall"
#   azure_firewall = var.azure_firewall
# }