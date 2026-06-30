resource "azurerm_resource_group" "team61_rg" {
  name     = var.name
  location = var.loc
}

resource "azurerm_virtual_network" "team61_vn" {
  name                = "team61-vn"
  location            = var.loc
  resource_group_name = var.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.team61_rg]
}

resource "azurerm_subnet" "team61_bas" {
  name                            = "team61-bas"
  resource_group_name             = var.name
  virtual_network_name            = azurerm_virtual_network.team61_vn.name
  address_prefixes                = ["10.0.0.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team61_vn]
}

resource "azurerm_subnet" "team61_appgw" {
  name                            = "team61-appgw"
  resource_group_name             = var.name
  virtual_network_name            = azurerm_virtual_network.team61_vn.name
  address_prefixes                = ["10.0.1.0/24"]
  default_outbound_access_enabled = true
  depends_on                      = [azurerm_virtual_network.team61_vn]
}

resource "azurerm_subnet" "team61_web" {
  name                            = "team61-web"
  resource_group_name             = var.name
  virtual_network_name            = azurerm_virtual_network.team61_vn.name
  address_prefixes                = ["10.0.2.0/24"]
  default_outbound_access_enabled = false
  service_endpoints               = ["Microsoft.Storage"]
  depends_on                      = [azurerm_virtual_network.team61_vn]
}

resource "azurerm_subnet" "team61_db" {
  name                            = "team61-db"
  resource_group_name             = var.name
  virtual_network_name            = azurerm_virtual_network.team61_vn.name
  address_prefixes                = ["10.0.3.0/24"]
  default_outbound_access_enabled = false
  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  depends_on = [azurerm_virtual_network.team61_vn]
}
