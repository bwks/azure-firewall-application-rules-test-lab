# Give yourself access to update AKV secrets/certificates
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "secrets_officer" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "cert_officer" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Create a Managed Identity for Azure Firewall access to AKV secrets/certificates
resource "azurerm_user_assigned_identity" "azfw_uaid" {
  name                = "azfw-uaid"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
}

resource "azurerm_role_assignment" "kv_cert_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.azfw_uaid.principal_id
}
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User" # For secrets
  principal_id         = azurerm_user_assigned_identity.azfw_uaid.principal_id
}

