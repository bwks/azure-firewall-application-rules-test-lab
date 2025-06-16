output "fireall_pip" {
  description = "Public IP address of the firewall"
  value       = azurerm_public_ip.fw_pip.ip_address
}
output "client_ip" {
  description = "Private IP address of client"
  value       = azurerm_network_interface.spoke1_vm_nic.private_ip_address
}
output "webserver_1_ip" {
  description = "Private IP address of webserver1"
  value       = azurerm_network_interface.spoke2_vm_1_nic.private_ip_address
}
output "webserver_2_ip" {
  description = "Private IP address of webserver2"
  value       = azurerm_network_interface.spoke2_vm_2_nic.private_ip_address
}
output "webserver_3_ip" {
  description = "Private IP address of webserver3"
  value       = azurerm_network_interface.spoke2_vm_3_nic.private_ip_address
}
