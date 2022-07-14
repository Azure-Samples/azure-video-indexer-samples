# create random string
resource "random_string" "random" {
  length      = 4
  numeric     = true
  lower       = true
  upper       = false
  special     = false
  min_numeric = 1
}

# create locals
locals {
  arm_file_path            = "./arm/vi.template.json"
  resource_version         = "${var.environment}-${random_string.random.id}"
  resource_version_compact = "${var.environment}${random_string.random.id}"
  required_tags = {
    name        = var.name
    environment = var.environment
    uid         = random_string.random.id
  }
}

# create resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.name}-${local.resource_version}"
  location = var.location
  tags     = local.required_tags
}

#--------------------------------------------------------------
# Media Services
#--------------------------------------------------------------

# create storage for media services
resource "azurerm_storage_account" "media_storage" {
  name                      = "mediastorage${local.resource_version_compact}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  tags                      = local.required_tags
}

# create media services
resource "azurerm_media_services_account" "media_services" {
  name                        = "mediaservices${local.resource_version_compact}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  storage_authentication_type = "System"
  tags                        = local.required_tags

  storage_account {
    id         = azurerm_storage_account.media_storage.id
    is_primary = true
  }

  identity {
    type = "SystemAssigned"
  }
}

#--------------------------------------------------------------
# Video Indexer
#--------------------------------------------------------------

# create user assigned managed identity
resource "azurerm_user_assigned_identity" "vi_uami" {
  name                = "vi-uami-${local.resource_version}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.required_tags
}

# create role assignement
resource "azurerm_role_assignment" "vi_media_services_access" {
  scope                = azurerm_media_services_account.media_services.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.vi_uami.principal_id
}

# deploy video indexer (using arm template)
resource "azurerm_resource_group_template_deployment" "vi" {
  resource_group_name = azurerm_resource_group.rg.name
  parameters_content = jsonencode({
    "name"                          = { value = "vi-${local.resource_version}" },
    "managedIdentityResourceId"     = { value = azurerm_user_assigned_identity.vi_uami.id },
    "mediaServiceAccountResourceId" = { value = azurerm_media_services_account.media_services.id }
    "tags"                          = { value = local.required_tags }
  })

  template_content = templatefile(local.arm_file_path, {})

  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "vi-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
  depends_on = [
    azurerm_media_services_account.media_services,
    azurerm_user_assigned_identity.vi_uami,
    azurerm_role_assignment.vi_media_services_access
  ]
}
