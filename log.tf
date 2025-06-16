resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_log_analytics_workspace" "firewall_logs" {
  name                = "law-firewall-logs"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_storage_account" "logs" {
  name                     = "logbucketzz${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.network_rg.name
  location                 = azurerm_resource_group.network_rg.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "firewall_diag" {
  name                       = "firewall-diagnostics"
  target_resource_id         = azurerm_firewall.hub_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.firewall_logs.id

  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
