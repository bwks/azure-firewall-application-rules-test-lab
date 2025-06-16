resource "azurerm_network_interface" "spoke1_vm_nic" {
  name                = "spoke1-vm-nic"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_workload_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke2_vm_1_nic" {
  name                = "spoke2-vm-1-nic"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_workload_subnet_1.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "spoke2_vm_2_nic" {
  name                = "spoke2-vm-2-nic"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_workload_subnet_2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke2_vm_3_nic" {
  name                = "spoke2-vm-3-nic"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_workload_subnet_3.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke1_vm" {
  name                = "spoke1-ubuntu2404-vm"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  size                = "Standard_B2ms"
  admin_username      = var.vm_username
  network_interface_ids = [
    azurerm_network_interface.spoke1_vm_nic.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = base64encode(<<EOF
#!/bin/bash
curl -OL https://github.com/bwks/netkraken/releases/download/v0.2.15/nk-x86_64-unknown-linux-gnu.tar.gz
tar -xvf nk-x86_64-unknown-linux-gnu.tar.gz
mv nk /usr/local/bin
EOF
  )
  depends_on = [
    azurerm_firewall_policy_rule_collection_group.main
  ]
}

# Internal CA No Inspection
resource "azurerm_linux_virtual_machine" "spoke2_vm_1" {
  name                = "spoke2-vm-1-ubuntu2404-vm"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  size                = "Standard_B2ms"
  admin_username      = var.vm_username
  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_1_nic.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = filebase64("./config/webserver1.yaml")
  depends_on = [
    azurerm_firewall_policy_rule_collection_group.main
  ]
}

# Internal CA Inspection
resource "azurerm_linux_virtual_machine" "spoke2_vm_2" {
  name                = "spoke2-vm-2-ubuntu2404-vm"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  size                = "Standard_B2ms"
  admin_username      = var.vm_username
  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_2_nic.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = filebase64("./config/webserver2.yaml")
  depends_on = [
    azurerm_firewall_policy_rule_collection_group.main
  ]
}

# Lets Encrypt Inspected
resource "azurerm_linux_virtual_machine" "spoke2_vm_3" {
  name                = "spoke2-vm-3-ubuntu2404-vm"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  size                = "Standard_B2ms"
  admin_username      = var.vm_username
  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_3_nic.id,
  ]
  admin_ssh_key {
    username   = var.vm_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = filebase64("./config/webserver3.yaml")
  depends_on = [
    azurerm_firewall_policy_rule_collection_group.main
  ]
}
