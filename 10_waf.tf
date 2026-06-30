resource "azurerm_web_application_firewall_policy" "team61_waf" {
  name                = "team61-waf-policy"
  resource_group_name = var.name
  location            = var.loc

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
  depends_on = [azurerm_resource_group.team61_rg]
}