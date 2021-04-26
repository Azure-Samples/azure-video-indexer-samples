provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "generalstorage" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  name                     = "generalstorage${random_string.random.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "mediacontainer" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.generalstorage,
  ]

  name                  = "media"
  storage_account_name  = azurerm_storage_account.generalstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "scenescontainer" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.generalstorage
  ]

  name                  = "scenes"
  storage_account_name  = azurerm_storage_account.generalstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "videoindexerinsights" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.generalstorage
  ]

  name                  = "videoindexerinsights"
  storage_account_name  = azurerm_storage_account.generalstorage.name
  container_access_type = "private"
}


resource "azurerm_storage_account" "videoindexerstorage" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  name                     = "videoindexerstorage${random_string.random.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "insightscontainer" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.videoindexerstorage
  ]

  name                  = "videoindexerinsights"
  storage_account_name  = azurerm_storage_account.videoindexerstorage.name
  container_access_type = "private"
}

resource "azurerm_media_services_account" "mediaservices" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.videoindexerstorage,
    random_string.random
  ]

  name                = "mediaservices${random_string.random.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account {
    id         = azurerm_storage_account.videoindexerstorage.id
    is_primary = true
  }
}

resource "azurerm_logic_app_workflow" "orchestrator" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "orchestratorlogicapp${random_string.random.result}"

  lifecycle {
    ignore_changes = [
      parameters
    ]
  }
}

resource "azurerm_logic_app_workflow" "indexer" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "indexerlogicapp${random_string.random.result}"

  lifecycle {
    ignore_changes = [
      parameters
    ]
  }
}

resource "azurerm_logic_app_workflow" "classifier" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "classifierlogicapp${random_string.random.result}"

  lifecycle {
    ignore_changes = [
      parameters
    ]
  }
}

resource "azurerm_search_service" "search" {

  depends_on = [
    azurerm_resource_group.rg,
    random_string.random
  ]

  name                = "searchservice${random_string.random.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"
}

resource "azurerm_app_service_plan" "appserviceplan" {
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  name     = "mlappserviceplan"
  kind     = "Linux"
  reserved = true

  sku {
    tier = "Standard"
    size = "P2V2"
  }
}

module "parserapi" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.generalstorage,
    azurerm_app_service_plan.appserviceplan
  ]

  source = "../parser/ParserAPI/deployment/webapp"

  resource_group               = azurerm_resource_group.rg.name
  docker_registry_url          = var.parser_docker_registry_url
  milliseconds_interval        = var.search_clips_interval_milliseconds
  key                          = var.parser_api_key
  location                     = var.location
  general_storage_account_name = azurerm_storage_account.generalstorage.name
  app_service_plan_id          = azurerm_app_service_plan.appserviceplan.id
  resource_suffix              = random_string.random.result
}

module "classifierpowerskill" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_media_services_account.mediaservices,
    azurerm_app_service_plan.appserviceplan
  ]

  source = "../AutoML_Vision_Classifier_Powerskill/deployment/webapp"

  powerskill_api_key  = var.classifierpowerskill_api_key
  resource_group      = azurerm_resource_group.rg.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  resource_suffix     = random_string.random.result

}

resource "azurerm_template_deployment" "terraform-arm" {

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_container.mediacontainer,
    azurerm_storage_container.insightscontainer,
    azurerm_logic_app_workflow.indexer,
    azurerm_logic_app_workflow.orchestrator,
    azurerm_logic_app_workflow.classifier,
    random_string.random
  ]

  name                = "armdeployment${random_string.random.result}"
  resource_group_name = var.resource_group_name

  template_body = file("template.json")

  parameters = {
    "subscriptionId"                             = var.subscription_id
    "location"                                   = var.location
    "storageAccounts_videostorageacct_name"      = azurerm_storage_account.videoindexerstorage.name
    "insightsContainerName"                      = azurerm_storage_container.insightscontainer.name
    "mediaContainerName"                         = azurerm_storage_container.mediacontainer.name
    "workflows_video_flow_logic_app_name"        = azurerm_logic_app_workflow.indexer.name
    "workflows_bloblistenerapp_name"             = azurerm_logic_app_workflow.orchestrator.name
    "workflows_enrich_with_classifications_name" = azurerm_logic_app_workflow.classifier.name
  }

  deployment_mode = "Incremental"
}
