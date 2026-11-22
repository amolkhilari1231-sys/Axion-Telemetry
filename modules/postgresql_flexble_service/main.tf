resource "random_password" "postgres_password" {
  for_each         = var.postgresql
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "postgresql" {
  for_each                      = var.postgresql
  name                          = each.value.name
  resource_group_name           = var.rgs
  location                      = var.location
  version                       = "12"
  public_network_access_enabled = true
  administrator_login           = each.value.admin_username
  administrator_password        = lookup(each.value, "admin_password", null) != null && lookup(each.value, "admin_password", "") != "" ? each.value.admin_password : random_password.postgres_password[each.key].result
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name = "B_Standard_B1ms"
}

output "postgresql_passwords" {
  value     = { for k, v in random_password.postgres_password : k => v.result }
  sensitive = true
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "postgresql_firewall_rule" {
  depends_on       = [azurerm_postgresql_flexible_server.postgresql]
  for_each         = var.postgresql
  name             = "postgresql-firewall-rule"
  server_id        = azurerm_postgresql_flexible_server.postgresql[each.key].id
  start_ip_address = "223.233.82.33"
  end_ip_address   = "223.233.82.33"
}