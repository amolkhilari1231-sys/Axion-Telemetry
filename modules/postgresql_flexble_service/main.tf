resource "azurerm_postgresql_flexible_server" "postgresql" {
  for_each                      = var.postgresql
  name                          = each.value.name
  resource_group_name           = var.rgs
  location                      = var.location
  version                       = lookup(each.value, "version", "15")
  public_network_access_enabled = true
  administrator_login           = each.value.admin_username
  administrator_password        = each.value.admin_password

  storage_mb = lookup(each.value, "storage_mb", 32768)

  sku_name = lookup(each.value, "sku_name", "B_Standard_B2s")

  lifecycle {
    ignore_changes = [
      zone,
      high_availability
    ]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "postgresql_firewall_rule" {
  depends_on       = [azurerm_postgresql_flexible_server.postgresql]
  for_each         = var.postgresql
  name             = "postgresql-firewall-rule"
  server_id        = azurerm_postgresql_flexible_server.postgresql[each.key].id
  start_ip_address = lookup(each.value, "firewall_start_ip", "0.0.0.0")
  end_ip_address   = lookup(each.value, "firewall_end_ip", "255.255.255.255")
}

