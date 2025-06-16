# Create the Private DNS Zone
resource "azurerm_private_dns_zone" "stuffandthings" {
  name                = "stuffandthings.internal"
  resource_group_name = azurerm_resource_group.network_rg.name
}

# Link the Private DNS Zone to the Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_link_stuffandthings" {
  name                  = "hub-vnet-link"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.stuffandthings.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "client_stuffandthings" {
  name                = "client"
  zone_name           = azurerm_private_dns_zone.stuffandthings.name
  resource_group_name = azurerm_resource_group.network_rg.name
  ttl                 = 300
  records             = [azurerm_network_interface.spoke1_vm_nic.private_ip_address]
}

resource "azurerm_private_dns_a_record" "webserver1_stuffandthings" {
  name                = "webserver1"
  zone_name           = azurerm_private_dns_zone.stuffandthings.name
  resource_group_name = azurerm_resource_group.network_rg.name
  ttl                 = 300
  records             = [azurerm_network_interface.spoke2_vm_1_nic.private_ip_address]
}

resource "azurerm_private_dns_a_record" "webserver2_stuffandthings" {
  name                = "webserver2"
  zone_name           = azurerm_private_dns_zone.stuffandthings.name
  resource_group_name = azurerm_resource_group.network_rg.name
  ttl                 = 300
  records             = [azurerm_network_interface.spoke2_vm_2_nic.private_ip_address]
}

resource "azurerm_private_dns_zone" "stratuslabs" {
  name                = "stratuslabs.net"
  resource_group_name = azurerm_resource_group.network_rg.name
}

# Link the Private DNS Zone to the Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_link_stratuslabs" {
  name                  = "hub-vnet-link-stratuslabs"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.stratuslabs.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "webserver3_stratuslabs" {
  name                = "webserver3"
  zone_name           = azurerm_private_dns_zone.stratuslabs.name
  resource_group_name = azurerm_resource_group.network_rg.name
  ttl                 = 300
  records             = [azurerm_network_interface.spoke2_vm_3_nic.private_ip_address]
}

