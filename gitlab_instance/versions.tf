terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-observability-dev"
    storage_account_name = "sttdb2ytk4dh"
    container_name       = "tfstate"
    key                  = "devops-dev"
  }
}

provider "azurerm" {
  features {}
}
