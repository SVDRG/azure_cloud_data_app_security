resource "azurerm_mysql_flexible_server" "team61_mysql_server" {
  name                   = "team61-mysql-server"
  resource_group_name    = var.name
  location               = var.loc
  administrator_login    = "team61"
  administrator_password = random_password.db_pswd.result
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.team61_db.id
  private_dns_zone_id    = azurerm_private_dns_zone.team61_db_dns.id
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.team61_db_dns_link]
}

resource "azurerm_mysql_flexible_database" "team61_wp_db" {
  name                = "wordpress"
  resource_group_name = var.name
  server_name         = azurerm_mysql_flexible_server.team61_mysql_server.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_unicode_ci"
}
