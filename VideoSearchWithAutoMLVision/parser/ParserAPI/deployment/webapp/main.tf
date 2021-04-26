# azurerm provider can be uncommented for independent deployment of this resource during dev
# provider "azurerm" {
#   subscription_id = var.subscription_id
#   features {}
#   skip_provider_registration = "true"
# }

resource "azurerm_app_service" "dockerapp" {
  location            = var.location
  resource_group_name = var.resource_group

  name                = "parserapi${var.resource_suffix}"
  app_service_plan_id = var.app_service_plan_id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                       = 5000
    DOCKER_REGISTRY_SERVER_URL          = var.docker_registry_url
    DOCKER_REGISTRY_SERVER_USERNAME     = var.docker_registry_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = var.docker_registry_password
    DEBUG                               = var.debug
    KEY					                        = var.key
    MILLISECONDS_INTERVAL               = var.milliseconds_interval
  }

  site_config {
    linux_fx_version  = "DOCKER|${var.docker_image}"
    always_on         = "true"
    min_tls_version   = 1.2
    health_check_path = "/api/healthcheck"
  }

  identity {
    type = "SystemAssigned"
  }
}
