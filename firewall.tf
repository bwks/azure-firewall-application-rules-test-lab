# Azure Firewall with Public IP
resource "azurerm_public_ip" "fw_pip" {
  name                = "firewall-public-ip"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_firewall" "hub_firewall" {
  name                = "hub-firewall"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.hub_fw_policy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_azure_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}
