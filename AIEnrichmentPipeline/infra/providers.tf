terraform {
  backend "azurerm" {}
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.42"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.6.0"
    }
  }
}

provider "azurerm" {
  version = "~> 2.51.0"
  features {}
}
