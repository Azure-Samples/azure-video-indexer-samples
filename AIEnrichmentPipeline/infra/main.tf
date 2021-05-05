locals {
  // These are variables which are common to all resources or frequently used
  // this should be passed to all modules
  shared_env = {
    tags = var.tags
    rg = {
      location = azurerm_resource_group.env.location
      name     = azurerm_resource_group.env.name
    }
  }
  input_container_name = "input"
}

resource "azurerm_resource_group" "env" {
  location = var.resource_group_location
  name     = var.resource_group_name
  tags     = var.tags
}

resource "azurerm_app_service_plan" "asp" {
  name                = "functionappserviceplan"
  resource_group_name = local.shared_env.rg.name
  location            = local.shared_env.rg.location
  tags                = local.shared_env.tags

  sku {
    tier = "ElasticPremium"
    size = "EP1"
  }

  kind             = "elastic"
  per_site_scaling = false
  reserved         = false
  is_xenon         = false


  maximum_elastic_worker_count = 10
}

## Calling the 'core' module and all components deployed underneath it
module "core" {
  source     = "./core"
  shared_env = local.shared_env
}

module "video_indexer" {
  source     = "./videoindexer"
  shared_env = local.shared_env
  vi_api_key = var.vi_api_key
}

module "video_workflow" {
  source     = "./logicapp"
  shared_env = local.shared_env
  law_id     = module.core.law_id
  law_key    = module.core.law_primary_shared_key
  // The module will look for an ARM template for the workflow in `./logicapp/${workflow_name}/armtemplate` 
  workflow_name = "videoworkflow"
  // The arm template must accept the parameters pass here in the root > parameters node of the arm template and push them into the workflow
  parameters = {
    viAccountId = module.video_indexer.account_id,
    viApiKey    = var.vi_api_key,
    viLocation  = var.resource_group_location,

  }
}

module "image_workflow" {
  source     = "./logicapp"
  shared_env = local.shared_env
  law_id     = module.core.law_id
  law_key    = module.core.law_primary_shared_key


  // The module will look for an ARM template for the workflow in `./logicapp/${workflow_name}/armtemplate` 
  workflow_name = "imageworkflow"
  // The arm template must accept the parameters pass here in the root > parameters node of the arm template and push them into the workflow
  parameters = {
    storageAccountName    = module.core.storage_account_name,
    storageAccountKey     = module.core.storage_account_key,
    computerVisionKey     = module.core.computer_vision_key,
    computerVisionUri     = module.core.computer_vision_uri,
    computerVisionVersion = var.computer_vision_version,
    imageResizeFuncId     = "${module.imageresize_function.function_details.id}/functions/ImageResize",
  }
}

module "digitaltextfile_workflow" {
  source     = "./logicapp"
  shared_env = local.shared_env
  law_id     = module.core.law_id
  law_key    = module.core.law_primary_shared_key

  workflow_name = "digitaltextfileworkflow"
  parameters = {
    storageAccountName = module.core.storage_account_name,
    storageAccountKey  = module.core.storage_account_key,
    textAnalyticsKey   = module.core.text_analytics_key,
    textAnalyticsUri   = module.core.text_analytics_uri,
    textTranslationKey = module.core.text_translation_key,
    textTranslationUri = module.core.text_translation_uri
  }
}

module "imageresize_function" {
  source        = "./func_deploy"
  function_name = "imageresize"

  releases_storage_account_name = module.core.releases_storage_account_name
  releases_storage_account_key  = module.core.releases_storage_account_key
  releases_storage_sas          = module.core.releases_account_sas
  releases_container_name       = module.core.releases_container_name
  app_service_plan_id           = azurerm_app_service_plan.asp.id

  shared_env = local.shared_env

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = module.core.appinsights_instrumentation_key
  }
}

module "workflowtrigger_function" {
  source        = "./func_deploy"
  function_name = "workflowtrigger"

  releases_storage_account_name = module.core.releases_storage_account_name
  releases_storage_account_key  = module.core.releases_storage_account_key
  releases_storage_sas          = module.core.releases_account_sas
  releases_container_name       = module.core.releases_container_name
  app_service_plan_id           = azurerm_app_service_plan.asp.id

  shared_env = local.shared_env

  app_settings = {
    "OutputServiceBusConfiguration:ConnectionString"    = module.core.importer_bus_connection_string,
    "OutputServiceBusConfiguration:QueueName"           = module.core.trigger_queue_name,
    "DataLakeConfiguration:Name"                        = module.core.storage_account_name,
    "DataLakeConfiguration:Key"                         = module.core.storage_account_key,
    "DataLakeConfiguration:Uri"                         = module.core.storage_account_dfs_endpoint,
    "DataLakeConfiguration:ConnectionString"            = module.core.storage_account_connection_string,
    "DataLakeConfiguration:InputContainerName"          = var.datalake_input_container_name,
    "DataLakeConfiguration:EnrichmentDataContainerName" = var.datalake_enrichmentdata_container_name,
    "APPINSIGHTS_INSTRUMENTATIONKEY"                    = module.core.appinsights_instrumentation_key
  }
}

module "orchestration_workflow" {
  source     = "./logicapp"
  shared_env = local.shared_env
  law_id     = module.core.law_id
  law_key    = module.core.law_primary_shared_key

  // The module will look for an ARM template for the workflow in `./logicapp/${workflow_name}/armtemplate` 
  workflow_name = "orchestrationworkflow"
  // The arm template must accept the parameters pass here in the root > parameters node of the arm template and push them into the workflow
  parameters = {
    videoworkflowid           = module.video_workflow.logic_app_details.id
    imageworkflowid           = module.image_workflow.logic_app_details.id
    digitaltextfileworkflowid = module.digitaltextfile_workflow.logic_app_details.id
    sbconnectionstring        = module.core.importer_bus_connection_string
    sbqueuename               = module.core.exporter_queue_name
    storageAccountName        = module.core.storage_account_name
    storageAccountKey         = module.core.storage_account_key
  }
}

module "dashboard" {
  source     = "./dashboards"
  shared_env = local.shared_env

  parameters = {
    subscriptionid = data.azurerm_subscription.current.subscription_id
    lawid          = module.core.law_id
    appinsightsid  = module.core.appinsights_app_id
  }
}

data "azurerm_subscription" "current" {
}

module "event_grid" {
  source                 = "./eventgrid"
  function_id            = "${module.workflowtrigger_function.function_details.id}/functions/WorkflowTriggerEventGridHandlerFunction"
  source_arm_resource_id = module.core.storage_account_id
  shared_env             = local.shared_env
}
