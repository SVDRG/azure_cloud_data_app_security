resource "azurerm_public_ip_prefix" "team61_ip_prefix" {
  name                = "team61-ip-prefix"
  location            = var.loc
  resource_group_name = var.name

  prefix_length = 30
  depends_on    = [azurerm_resource_group.team61_rg]
}

resource "azurerm_public_ip" "team61_basip" {
  name                = "team61-basip"
  resource_group_name = var.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.team61_ip_prefix.id
  depends_on          = [azurerm_resource_group.team61_rg]
}

resource "azurerm_public_ip" "team61_appgwip" {
  name                = "team61-appgwip"
  resource_group_name = var.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.team61_ip_prefix.id
  depends_on          = [azurerm_resource_group.team61_rg]
}

resource "azurerm_public_ip" "team61_natgwip" {
  name                = "team61-natgwip"
  resource_group_name = var.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.team61_ip_prefix.id
  depends_on          = [azurerm_resource_group.team61_rg]
}

output "basip" {
  value = azurerm_public_ip.team61_basip.ip_address
}

output "appgwip" {
  value = azurerm_public_ip.team61_appgwip.ip_address
}

output "natgwip" {
  value = azurerm_public_ip.team61_natgwip.ip_address
}