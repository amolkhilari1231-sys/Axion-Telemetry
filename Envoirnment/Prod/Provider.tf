terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "QA_Storage"
    storage_account_name = "terraformqastorage"
    container_name       = "terraformqastate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
