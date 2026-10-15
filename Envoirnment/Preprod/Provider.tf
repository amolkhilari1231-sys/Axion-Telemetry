terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "QA_Storage"
    storage_account_name = "terraformqastorage"
    container_name       = "terraformqastate"
    key                  = "preprod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
