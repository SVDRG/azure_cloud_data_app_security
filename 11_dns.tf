resource "azurerm_dns_zone" "team61_dns" {
  name                = "svdrg.cloud"
  resource_group_name = azurerm_resource_group.team61_rg.name
  depends_on          = [azurerm_resource_group.team61_rg]
}

resource "azurerm_dns_a_record" "team61_dns_a" {
  name                = "@"
  zone_name           = azurerm_dns_zone.team61_dns.name
  resource_group_name = azurerm_resource_group.team61_rg.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.team61_appgwip.id
}

resource "azurerm_private_dns_zone" "team61_db_dns" {
  name                = "team61.mysql.database.azure.com"
  resource_group_name = var.name

  depends_on = [azurerm_resource_group.team61_rg]
}

resource "azurerm_private_dns_zone_virtual_network_link" "team61_db_dns_link" {
  name                  = "team61-db-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.team61_db_dns.name
  virtual_network_id    = azurerm_virtual_network.team61_vn.id
  resource_group_name   = azurerm_resource_group.team61_rg.name
}