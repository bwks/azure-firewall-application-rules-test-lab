# Create resource group
resource "azurerm_resource_group" "network_rg" {
  name     = "hub-spoke-network-rg"
  location = "Australia East"
}
