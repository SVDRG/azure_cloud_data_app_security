data "azurerm_client_config" "team61_config" {}

data "azuread_group" "team61_group" {
  display_name     = "team61"
  security_enabled = true
}

resource "azurerm_key_vault" "team61_kv" {
  name                        = "team61-kv-v4"
  location                    = var.loc
  resource_group_name         = var.name
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.team61_config.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.team61_config.tenant_id
    object_id = data.azuread_group.team61_group.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Set", "List", "Delete", "Purge"
    ]

    storage_permissions = [
      "Get",
    ]

    certificate_permissions = ["Get", "List", "Create", "Delete", "Import", "Update", "Purge"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.team61_config.tenant_id
    object_id = azurerm_user_assigned_identity.appgw_id.principal_id

    secret_permissions      = ["Get"]
    certificate_permissions = ["Get"]
  }
}

resource "random_password" "db_pswd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "db_pswd" {
  name         = "db-pswd"
  value        = random_password.db_pswd.result
  key_vault_id = azurerm_key_vault.team61_kv.id
  depends_on   = [azurerm_key_vault.team61_kv]
}

resource "azurerm_key_vault_certificate" "team61_cert" {
  name         = "team61-appgw-cert"
  key_vault_id = azurerm_key_vault.team61_kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      key_usage          = ["cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyCertSign", "keyEncipherment"]
      subject            = "CN=svdrg.cloud"
      validity_in_months = 12
    }
  }
  depends_on = [azurerm_key_vault.team61_kv]
}
