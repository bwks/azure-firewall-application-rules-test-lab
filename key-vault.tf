resource "random_string" "key_vault_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_key_vault" "key_vault" {
  name                       = "stuffandthingzz${random_string.key_vault_suffix.result}" # must be globally unique, 3-24 alphanumeric characters
  location                   = azurerm_resource_group.network_rg.location
  resource_group_name        = azurerm_resource_group.network_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard" # or "premium"
  purge_protection_enabled   = true       # recommended best practice
  soft_delete_retention_days = 7          # optional, default is 90
  enable_rbac_authorization  = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules = [
      var.local_public_ip # allows uploading of the certificate from local machine.
    ]

  }
}

resource "azurerm_key_vault_certificate" "azfw_ca" {
  name         = "azfw-ca"
  key_vault_id = azurerm_key_vault.key_vault.id

  certificate {
    contents = filebase64("./cert/interCA.pfx")
    # password = var.cert_password
  }
  depends_on = [
    azurerm_role_assignment.cert_officer,
    azurerm_role_assignment.secrets_officer,
  ]
}
