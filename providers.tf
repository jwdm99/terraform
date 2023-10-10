terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.72.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
        spacelift = {
      source = "spacelift.io/spacelift-io/spacelift"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}
