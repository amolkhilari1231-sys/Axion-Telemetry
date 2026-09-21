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