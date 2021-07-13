output "law_id" {
  value = azurerm_log_analytics_workspace.core.id
}

output "law_primary_shared_key" {
  value = azurerm_log_analytics_workspace.core.primary_shared_key
}

output "storage_account" {
  value = azurerm_storage_account.core
}

output "storage_account_name" {
  value = azurerm_storage_account.core.name
}

output "storage_account_location" {
  value = azurerm_storage_account.core.location
}

output "storage_account_id" {
  value = azurerm_storage_account.core.id
}

output "storage_account_key" {
  value = azurerm_storage_account.core.primary_access_key
}

output "storage_account_dfs_endpoint" {
  value = azurerm_storage_account.core.primary_dfs_endpoint
}

output "storage_account_connection_string" {
  value = azurerm_storage_account.core.primary_blob_connection_string
}

output "releases_storage_account_id" {
  value = azurerm_storage_account.releases.id
}

output "releases_storage_account_name" {
  value = azurerm_storage_account.releases.name
}

output "releases_storage_account_key" {
  value = azurerm_storage_account.releases.primary_access_key
}

output "releases_container_name" {
  value = azurerm_storage_container.deployments.name
}

output "releases_account_sas" {
  value = data.azurerm_storage_account_sas.sas.sas
}

output "computer_vision_uri" {
  value = azurerm_cognitive_account.corecomputervision.endpoint
}

output "computer_vision_key" {
  value = azurerm_cognitive_account.corecomputervision.primary_access_key
}

output "text_analytics_uri" {
  value = azurerm_cognitive_account.coretextanalytics.endpoint
}

output "text_analytics_key" {
  value = azurerm_cognitive_account.coretextanalytics.primary_access_key
}

output "text_translation_uri" {
  value = azurerm_cognitive_account.coretexttranslation.endpoint
}

output "text_translation_key" {
  value = azurerm_cognitive_account.coretexttranslation.primary_access_key
}

output "importer_bus_connection_string" {
  value = azurerm_servicebus_namespace.importer_servicebus.default_primary_connection_string
}

output "exporter_queue_name" {
  value = azurerm_servicebus_queue.exporter.name
}

output "trigger_queue_name" {
  value = azurerm_servicebus_queue.trigger.name
}

output "trigger_queue_namespace_name" {
  value = azurerm_servicebus_queue.trigger.namespace_name
}

output "exporter_queue_namespace_name" {
  value = azurerm_servicebus_queue.exporter.namespace_name
}

output "appinsights_instrumentation_key" {
  value = azurerm_application_insights.appinsights.instrumentation_key
}

output "appinsights_name" {
  value = azurerm_application_insights.appinsights.name
}

output "appinsights_resource_group" {
  value = azurerm_application_insights.appinsights.resource_group_name
}

output "appinsights_app_id" {
  value = azurerm_application_insights.appinsights.app_id
}
