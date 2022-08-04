resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

resource "azurerm_storage_account" "core" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags

  name                      = "corestor${random_string.random.result}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = "false"
  is_hns_enabled            = true
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "test-data" {
  name                  = "test-data"
  storage_account_name  = azurerm_storage_account.core.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "input" {
  name                  = "input"
  storage_account_name  = azurerm_storage_account.core.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "enrichment-data" {
  name                  = "enrichment-data"
  storage_account_name  = azurerm_storage_account.core.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "releases" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags

  name                      = "release${random_string.random.result}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = "false"
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "deployments" {
  name                  = "function"
  storage_account_name  = azurerm_storage_account.releases.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.releases.primary_connection_string
  https_only        = true
  start             = join("-", [formatdate("YYYY", timestamp()), "01", "01"])
  expiry            = join("-", [formatdate("YYYY", timestamp()) + 1, "12", "31"])
  resource_types {
    object    = true
    container = false
    service   = false
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}
