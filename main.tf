# Configure Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  # subscription_id = "abcdef-xxxxx-yada-yada"
  features {}
}
