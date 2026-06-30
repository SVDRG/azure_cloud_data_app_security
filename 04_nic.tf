resource "azurerm_network_interface" "team61_bas_nic" {
  name                = "team61-bas-nic"
  location            = var.loc
  resource_group_name = var.name

  ip_configuration {
    name                          = "team61-bas-nic-ip"
    subnet_id                     = azurerm_subnet.team61_bas.id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.0.11"
    public_ip_address_id          = azurerm_public_ip.team61_basip.id
  }
  depends_on = [ azurerm_subnet.team61_bas ]
}

resource "azurerm_network_interface" "team61_web_nic" {
  name                = "team61-web-nic"
  location            = var.loc
  resource_group_name = var.name

  ip_configuration {
    name                          = "team61-web-nic-ip"
    subnet_id                     = azurerm_subnet.team61_web.id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.2.11"
  }
  depends_on = [ azurerm_subnet.team61_web ]
}