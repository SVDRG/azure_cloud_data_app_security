resource "azurerm_network_interface_security_group_association" "team61_bas_ssh" {
  network_interface_id      = azurerm_network_interface.team61_bas_nic.id
  network_security_group_id = azurerm_network_security_group.team61_nsg_ssh.id
}

resource "azurerm_network_interface_security_group_association" "team61_vm_ssh_https" {
  network_interface_id      = azurerm_network_interface.team61_web_nic.id
  network_security_group_id = azurerm_network_security_group.team61_nsg_ssh_https.id
}

resource "azurerm_subnet_network_security_group_association" "team61_appgw_assoc" {
  subnet_id                 = azurerm_subnet.team61_appgw.id
  network_security_group_id = azurerm_network_security_group.team61_nsg_appgw.id
}

resource "azurerm_subnet_network_security_group_association" "team61_db_nsg_link" {
  subnet_id                 = azurerm_subnet.team61_db.id
  network_security_group_id = azurerm_network_security_group.team61_db_nsg.id
}
