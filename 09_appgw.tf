locals {
  backend_address_pool_name      = "${azurerm_virtual_network.team61_vn.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.team61_vn.name}-feport-https"
  frontend_ip_configuration_name = "${azurerm_virtual_network.team61_vn.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.team61_vn.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.team61_vn.name}-httpslstn"
  request_routing_rule_name      = "${azurerm_virtual_network.team61_vn.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.team61_vn.name}-rdrcfg"
  ssl_certificate_name           = "${azurerm_virtual_network.team61_vn.name}-sslcert"
}

resource "azurerm_user_assigned_identity" "appgw_id" {
  name                = "team61-appgw-identity"
  resource_group_name = var.name
  location            = var.loc

  depends_on = [azurerm_resource_group.team61_rg]
}

resource "azurerm_application_gateway" "team61_appgw" {
  name                = "team61-appgw"
  resource_group_name = var.name
  location            = var.loc

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_id.id]
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.team61_appgw.id
  }

  ssl_certificate {
    name                = local.ssl_certificate_name
    key_vault_secret_id = azurerm_key_vault_certificate.team61_cert.versionless_secret_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.team61_appgwip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = [
      azurerm_network_interface.team61_web_nic.private_ip_address
    ]
  }

  trusted_root_certificate {
    name                = "backend-root-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.team61_cert.versionless_secret_id
  }

  probe {
    name                                      = "team61-appgw-probe"
    protocol                                  = "Https"
    port                                      = 443
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    probe_name                          = "team61-appgw-probe"
    pick_host_name_from_backend_address = false
    host_name                           = "svdrg.cloud"
    trusted_root_certificate_names      = ["backend-root-cert"]
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.team61_waf.id
  depends_on         = [azurerm_resource_group.team61_rg, azurerm_key_vault_certificate.team61_cert]
}
