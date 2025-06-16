# Create Firewall Policy
resource "azurerm_firewall_policy" "hub_fw_policy" {
  name                = "hub-firewall-policy"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  sku                 = "Premium" # Match your firewall SKU
  dns {
    proxy_enabled = true
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.azfw_uaid.id]
  }

  tls_certificate {
    key_vault_secret_id = azurerm_key_vault_certificate.azfw_ca.secret_id
    name                = azurerm_key_vault_certificate.azfw_ca.name
  }

  depends_on = [
    azurerm_role_assignment.kv_cert_user,
    azurerm_role_assignment.kv_secrets_user,
  ]
}

# Create Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "main-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.hub_fw_policy.id
  priority           = 500

  # Network Rule Collection for ICMP
  network_rule_collection {
    name     = "allow-icmp-rfc1918"
    priority = 1000
    action   = "Allow"

    rule {
      name                  = "icmp-from-rfc1918"
      protocols             = ["ICMP"]
      source_addresses      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }

  # Application Rule Collections
  application_rule_collection {
    name     = "spoke-to-spoke-web"
    priority = 1100
    action   = "Allow"

    rule {
      name             = "no-inspect-to-webserver1-stuffandthings"
      source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
      destination_fqdns = [
        "${azurerm_private_dns_a_record.webserver1_stuffandthings.name}.${azurerm_private_dns_zone.stuffandthings.name}",
      ]
      terminate_tls = false

      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name             = "inspect-to-webserver2-stuffandthings"
      source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
      destination_fqdns = [
        "${azurerm_private_dns_a_record.webserver2_stuffandthings.name}.${azurerm_private_dns_zone.stuffandthings.name}",
      ]
      terminate_tls = true

      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "inspect-to-webserver3-stratuslabs"
      source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
      destination_fqdns = [
        "${azurerm_private_dns_a_record.webserver3_stratuslabs.name}.${azurerm_private_dns_zone.stratuslabs.name}",
      ]
      terminate_tls = true
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
  application_rule_collection {
    name     = "spoke-to-internet"
    priority = 1200
    action   = "Allow"

    rule {
      name             = "inspect-to-google"
      source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
      destination_fqdns = [
        "google.com"
      ]
      terminate_tls = true
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name             = "inspect-bogus"
      source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
      destination_fqdns = [
        "idontexist.intheether"
      ]
      terminate_tls = true
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    # rule {
    #   name             = "no-inspect-bogus"
    #   source_addresses = azurerm_subnet.spoke1_workload_subnet.address_prefixes
    #   destination_fqdns = [
    #     "idontexist-no-inspect.intheether"
    #   ]
    #   terminate_tls = false
    #   protocols {
    #     type = "Http"
    #     port = 80
    #   }
    #   protocols {
    #     type = "Https"
    #     port = 443
    #   }
    # }

    rule {
      name              = "non-inspected-all"
      source_addresses  = ["*"]
      destination_fqdns = ["*"]
      terminate_tls     = false

      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  nat_rule_collection {
    name     = "ssh-dnat-rules"
    priority = 1400 # Collection-level priority
    action   = "Dnat"

    rule {
      name                = "SSH-To-Spoke1-VM"
      source_addresses    = [var.local_public_ip]               # Replace with your allowed source IP
      destination_address = azurerm_public_ip.fw_pip.ip_address # Firewall public IP
      destination_ports   = ["2290"]                            # External port
      protocols           = ["TCP"]
      translated_address  = azurerm_network_interface.spoke1_vm_nic.private_ip_address
      translated_port     = "22"
    }
    rule {
      name                = "SSH-To-Spoke2-VM-1"
      source_addresses    = [var.local_public_ip]               # Replace with your allowed source IP
      destination_address = azurerm_public_ip.fw_pip.ip_address # Firewall public IP
      destination_ports   = ["2291"]                            # External port
      protocols           = ["TCP"]
      translated_address  = azurerm_network_interface.spoke2_vm_1_nic.private_ip_address
      translated_port     = "22"
    }
    rule {
      name                = "SSH-To-Spoke2-VM-2"
      source_addresses    = [var.local_public_ip]               # Replace with your allowed source IP
      destination_address = azurerm_public_ip.fw_pip.ip_address # Firewall public IP
      destination_ports   = ["2292"]                            # External port
      protocols           = ["TCP"]
      translated_address  = azurerm_network_interface.spoke2_vm_2_nic.private_ip_address
      translated_port     = "22"
    }
    rule {
      name                = "SSH-To-Spoke2-VM-3"
      source_addresses    = [var.local_public_ip]               # Replace with your allowed source IP
      destination_address = azurerm_public_ip.fw_pip.ip_address # Firewall public IP
      destination_ports   = ["2293"]                            # External port
      protocols           = ["TCP"]
      translated_address  = azurerm_network_interface.spoke2_vm_3_nic.private_ip_address
      translated_port     = "22"
    }
  }
}
