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

# [Step 1] AppGW의 백엔드 풀과 Web VM의 네트워크 카드(NIC)를 연결하는 접착제
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "team61_appgw_nic_link" {

  # 1. 대상 네트워크 카드: 04_nic.tf에 있는 Web VM의 NIC를 가리킵니다.
  network_interface_id = azurerm_network_interface.team61_web_nic.id

  # 2. NIC의 IP 설정 이름: 04_nic.tf에서 지어준 ip_configuration의 이름
  ip_configuration_name = "team61-web-nic-ip"

  # 3. 대상 백엔드 풀: 방금 만든 AppGW의 첫 번째 백엔드 풀 ID를 가져옵니다.
  backend_address_pool_id = tolist(azurerm_application_gateway.team61_appgw.backend_address_pool)[0].id

  depends_on = [
    azurerm_application_gateway.team61_appgw,
    azurerm_network_interface.team61_web_nic
  ]
}
