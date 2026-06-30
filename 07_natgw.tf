resource "azurerm_nat_gateway" "team61_natgw" {
  name                    = "team61-natgw"
  location                = var.loc
  resource_group_name     = var.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = "4"
  depends_on              = [azurerm_resource_group.team61_rg]
}

resource "azurerm_nat_gateway_public_ip_association" "team61_natgw_pip" {
  nat_gateway_id       = azurerm_nat_gateway.team61_natgw.id
  public_ip_address_id = azurerm_public_ip.team61_natgwip.id
}

resource "azurerm_subnet_nat_gateway_association" "team61_natgw_web_link" {
  subnet_id      = azurerm_subnet.team61_web.id
  nat_gateway_id = azurerm_nat_gateway.team61_natgw.id
}