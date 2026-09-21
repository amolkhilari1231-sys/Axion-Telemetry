resource "azurerm_postgresql_flexible_server" "postgresql"{
    for_each = var.postgresql
  name                          = each.value.name
  resource_group_name           = each.value.rg_name
  location                      = each.value.location
  version                       = "12"
  public_network_access_enabled = true
  administrator_login           = each.value.admin_username
  administrator_password        = each.value.admin_password
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"

}

resource "azurerm_postgresql_flexible_server_firewall_rule" "postgresql_firewall_rule" {
  name             = "postgresql-firewall-rule"
  server_id        = azurerm_postgresql_flexible_server.postgresql[each.key].id
  start_ip_address = "*"
  end_ip_address   = "*"
}