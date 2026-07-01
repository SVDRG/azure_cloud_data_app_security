resource "azurerm_linux_virtual_machine" "team61_vmbas" {
  name                  = "team61-vmbas"
  location              = var.loc
  resource_group_name   = var.name
  size                  = "Standard_B2ts_v2"
  admin_username        = "team61"
  network_interface_ids = [azurerm_network_interface.team61_bas_nic.id]

  admin_ssh_key {
    username   = "team61"
    public_key = file("id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
    version   = "9.3.20231113"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-lvm"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_linux_virtual_machine" "team61_vmweb" {
  name                  = "team61-vmweb"
  location              = var.loc
  resource_group_name   = var.name
  size                  = "Standard_B2ts_v2"
  admin_username        = "team61"
  network_interface_ids = [azurerm_network_interface.team61_web_nic.id]

  admin_ssh_key {
    username   = "team61"
    public_key = file("id_rsa.pub")
  }
  user_data = base64encode(templatefile("install.sh", {
    kv_name        = azurerm_key_vault.team61_kv.name
    db_host        = azurerm_mysql_flexible_server.team61_mysql_server.fqdn
    uami_client_id = azurerm_user_assigned_identity.appgw_id.client_id
  }))
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
    version   = "9.3.20231113"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-lvm"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_id.id]
  }

  secret {
    key_vault_id = azurerm_key_vault.team61_kv.id
    certificate {
      url = azurerm_key_vault_certificate.team61_cert.secret_id
    }
  }
}
