resource "azurerm_network_security_group" "team61_nsg_ssh" {
  name                = "team61-nsg-ssh"
  location            = var.loc
  resource_group_name = var.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.team61_rg]
}

resource "azurerm_network_security_group" "team61_nsg_ssh_https" {
  name                = "team61-nsg-ssh-https"
  location            = var.loc
  resource_group_name = var.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.team61_rg]
}

resource "azurerm_network_security_group" "team61_nsg_appgw" {
  name                = "team61-nsg-appgw"
  location            = var.loc
  resource_group_name = var.name

  # 1. 사용자 접속 허용 (HTTPS)
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*" # 전 세계 어디서든 접속 허용
    destination_address_prefix = "*"
  }

  # 2. App Gateway 관리용 필수 포트 (WAF v2 필수)
  security_rule {
    name                       = "Allow-GatewayManager-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager" # Azure 인프라 서비스 태그
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.team61_rg]
}