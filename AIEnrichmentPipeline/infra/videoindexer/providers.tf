terraform {
  required_version = ">= 0.13"
  required_providers {
    shell = {
      source  = "scottwinkler/shell"
      version = "=1.7.3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.0.0"
    }
  }

}
