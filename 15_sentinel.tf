# 2. [Step 1] LAW에 Sentinel 솔루션 얹기 (Sentinel 켜기)
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "team61_sentinel" {
  workspace_id = azurerm_log_analytics_workspace.team61_log.id
}

# 3. [Step 2] 데이터 커넥터: Entra ID(구 Azure AD) 로그 수집기 달기
# 방금 동기화한 계정들의 로그인 기록을 Sentinel로 쫙 빨아들입니다.
/* resource "azurerm_sentinel_data_connector_azure_active_directory" "team61_aad_connector" {
  name                       = "team61-aad-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.team61_sentinel.workspace_id
  tenant_id                  = data.azurerm_client_config.team61_config.tenant_id
}
 */
# 4. [Step 3] 탐지 규칙: KQL(Kusto Query Language)을 이용한 간단한 알람 룰 세팅
resource "azurerm_sentinel_alert_rule_scheduled" "team61_alert_rule" {
  name                       = "detect-suspicious-login-v5"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.team61_log.id
  display_name               = "비정상 로그인 시도 탐지"
  severity                   = "High"
  depends_on                 = [azurerm_log_analytics_workspace.team61_log, azurerm_sentinel_log_analytics_workspace_onboarding.team61_sentinel]

  # 탐지 로직 (예: 실패한 로그인 기록을 찾는 쿼리)
  query = <<QUERY
SigninLogs
| where ResultType != "0"
| summarize count() by UserPrincipalName, IPAddress
| where count_ > 5
QUERY
}
