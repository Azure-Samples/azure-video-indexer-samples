variable shared_env {
  type = any
}
variable vi_api_key {
  description = "The API key for accessing the VI API. Docs on how to obtain here: https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis#subscribe-to-the-api"
}
resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

# Create a media services instance

resource "azurerm_storage_account" "media_storage" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags

  account_tier              = "Standard"
  account_replication_type  = "LRS"
  name                      = "mediastor${random_string.random.result}"
  allow_blob_public_access  = "false"
  enable_https_traffic_only = true
}

resource "azurerm_media_services_account" "media" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name

  name = "mediastor${random_string.random.result}"
  storage_account {
    id         = azurerm_storage_account.media_storage.id
    is_primary = true
  }
}

# Create the VI SP used by Video indexer to talk to Media services
resource "azuread_application" "vi" {
  name                       = "${random_string.random.result}vi"
  identifier_uris            = ["http://${random_string.random.result}vi"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true

}

resource "azuread_service_principal" "vi" {
  application_id               = azuread_application.vi.application_id
  app_role_assignment_required = false
}

resource "random_string" "pw" {
  length = 24
}

resource "azuread_service_principal_password" "vi" {
  service_principal_id = azuread_service_principal.vi.id
  value                = random_string.pw.result
  # Review best way forward with this setting
  end_date = "2050-01-01T01:02:03Z"
}

# Assign permissions for the VI SP to access the media services account
resource "azurerm_role_assignment" "vi_mediaservices_access" {
  scope                = azurerm_media_services_account.media.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.vi.object_id
}

# Create the VI instance via the VI API
data "azurerm_client_config" "current" {
}

# AAD SP's take time to replicate so aren't usable immediately after creation. 
# This resource causes a wait to occur at create time to account for this
resource "time_sleep" "wait_40_seconds" {
  depends_on      = [azuread_service_principal_password.vi]
  create_duration = "40s"
}


resource "shell_script" "videoindexer_account" {
  depends_on = [azurerm_role_assignment.vi_mediaservices_access, azuread_service_principal_password.vi, time_sleep.wait_40_seconds]

  lifecycle_commands {
    create = "pwsh ${path.module}/scripts/videoindexer.ps1 -type create"
    read   = "pwsh ${path.module}/scripts/videoindexer.ps1 -type read"
    update = "pwsh ${path.module}/scripts/videoindexer.ps1 -type update"
    delete = "pwsh ${path.module}/scripts/videoindexer.ps1 -type delete"
  }

  environment = {
    debug_log = true
    LOCATION  = var.shared_env.rg.location
    API_KEY   = var.vi_api_key
    # Why jsonencode then jsondecode?
    #
    # This is a workaround for the lack of validation in the shell provider. 
    # The intent is to ensure that the provider is only called if the `CREATE_JSON` outputs a valid JSON document
    #
    # This approach will catch formatting issues (missing commas or inputs with special charecters) which would cause the script to fail
    # and show these issues as a readable terraform error message.
    CREATE_JSON = jsonencode(jsondecode(<<JSON
      {
        "subscriptionId": "${data.azurerm_client_config.current.subscription_id}",
        "resourceGroup": "${var.shared_env.rg.name}",
        "resource": "${azurerm_media_services_account.media.name}",
        "aadTenantId": "${data.azurerm_client_config.current.tenant_id}",
        "aadConnection": {
          "applicationId": "${azuread_application.vi.application_id}",
          "applicationKey": "${azuread_service_principal_password.vi.value}"
        },
        "autoScale": true
      }
JSON
    ))
  }
}
