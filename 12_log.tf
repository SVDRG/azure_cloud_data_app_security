resource "azurerm_log_analytics_workspace" "team61_log" {
  name                = "team61-log-v3"
  location            = var.loc
  resource_group_name = var.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  depends_on          = [azurerm_resource_group.team61_rg]
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diagnostic-setting"
  target_resource_id         = azurerm_application_gateway.team61_appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.team61_log.id

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}