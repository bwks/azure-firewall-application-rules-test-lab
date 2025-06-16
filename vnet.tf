# Hub Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
}
resource "azurerm_subnet" "hub_azure_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Spoke 1 Virtual Network
resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "spoke1-vnet"
  address_space       = ["192.168.0.0/22"]
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  dns_servers         = [azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address]
}
resource "azurerm_subnet" "spoke1_workload_subnet" {
  name                            = "workload-subnet"
  resource_group_name             = azurerm_resource_group.network_rg.name
  virtual_network_name            = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes                = ["192.168.0.0/24"]
  default_outbound_access_enabled = false
}

# Spoke 2 Virtual Network
resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "spoke2-vnet"
  address_space       = ["172.16.0.0/22"]
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  dns_servers         = [azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address]
}

resource "azurerm_subnet" "spoke2_workload_subnet_1" {
  name                            = "workload-subnet-1"
  resource_group_name             = azurerm_resource_group.network_rg.name
  virtual_network_name            = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes                = ["172.16.1.0/24"]
  default_outbound_access_enabled = false
}
resource "azurerm_subnet" "spoke2_workload_subnet_2" {
  name                            = "workload-subnet-2"
  resource_group_name             = azurerm_resource_group.network_rg.name
  virtual_network_name            = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes                = ["172.16.2.0/24"]
  default_outbound_access_enabled = false
}
resource "azurerm_subnet" "spoke2_workload_subnet_3" {
  name                            = "workload-subnet-3"
  resource_group_name             = azurerm_resource_group.network_rg.name
  virtual_network_name            = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes                = ["172.16.3.0/24"]
  default_outbound_access_enabled = false
}

# Peer Hub to Spoke1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke1_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

# Peer Hub to Spoke2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.network_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

# Network Security Group for workload subnets
resource "azurerm_network_security_group" "workload_nsg" {
  name                = "workload-nsg"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  security_rule {
    name                       = "AllowFromRFC1918"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DenyAny"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Spoke 1 workload subnet
resource "azurerm_subnet_network_security_group_association" "spoke1_workload" {
  subnet_id                 = azurerm_subnet.spoke1_workload_subnet.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}

# Associate NSG with Spoke 2 workload subnet
resource "azurerm_subnet_network_security_group_association" "spoke2_workload_1" {
  subnet_id                 = azurerm_subnet.spoke2_workload_subnet_1.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "spoke2_workload_2" {
  subnet_id                 = azurerm_subnet.spoke2_workload_subnet_2.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "spoke2_workload_3" {
  subnet_id                 = azurerm_subnet.spoke2_workload_subnet_3.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}


# Route table for RFC1918 traffic redirection
resource "azurerm_route_table" "spoke" {
  name                = "spoke-routes"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_route" "default" {
  name                   = "default"
  route_table_name       = azurerm_route_table.spoke.name
  resource_group_name    = azurerm_resource_group.network_rg.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}

# Associate route table with spoke subnets
resource "azurerm_subnet_route_table_association" "spoke1_routing" {
  subnet_id      = azurerm_subnet.spoke1_workload_subnet.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "spoke2_routing_1" {
  subnet_id      = azurerm_subnet.spoke2_workload_subnet_1.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "spoke2_routing_2" {
  subnet_id      = azurerm_subnet.spoke2_workload_subnet_2.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_subnet_route_table_association" "spoke2_routing_3" {
  subnet_id      = azurerm_subnet.spoke2_workload_subnet_3.id
  route_table_id = azurerm_route_table.spoke.id
}
