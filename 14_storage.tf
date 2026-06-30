# 1. 보안 스토리지 계정 생성
resource "azurerm_storage_account" "team61_storage" {
  name                     = "team61storagev3" 
  resource_group_name      = var.name
  location                 = var.loc
  account_tier             = "Standard"
  account_replication_type = "LRS"

  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true 

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.team61_web.id]
    bypass                     = ["AzureServices"]
  }
}

# 2. 애플리케이션 파일 저장용 Blob 스토리지(컨테이너) 생성
resource "azurerm_storage_container" "team61_container" {
  name                  = "secure-data-blob"
  storage_account_id  = azurerm_storage_account.team61_storage.id
  container_access_type = "private" # 외부 직통 URL 접근 차단
}

# 3. 마스터키를 Key Vault 금고에 보관
resource "azurerm_key_vault_secret" "storage_access_key" {
  name         = "storage-primary-key"
  value        = azurerm_storage_account.team61_storage.primary_access_key
  key_vault_id = azurerm_key_vault.team61_kv.id
  depends_on   = [azurerm_key_vault.team61_kv, azurerm_storage_account.team61_storage]
}

#  [추가] 4. 비밀 링크 (SAS 토큰) 보안 기능 정의
data "azurerm_storage_account_sas" "team61_sas" {
  connection_string = azurerm_storage_account.team61_storage.primary_connection_string
  https_only        = true

  # 토큰 유효 기간 설정 (현재 시간부터 24시간 동안만 유효)
  start  = "2026-06-26T00:00:00Z"
  expiry = "2026-06-27T00:00:00Z"

  # 허용할 자원 유형 및 서비스 (Blob 파일 접근 허용)
  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  # 제한할 권한 (오직 읽기 및 목록 보기만 가능, 삭제/수정 불가)
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}
