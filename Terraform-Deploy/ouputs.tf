output "video_indexer_resource_id" {
  description = "The video indexer resource id."
  value       = jsondecode(azurerm_resource_group_template_deployment.vi.output_content).resourceId.value
}

output "video_indexer_account_name" {
  description = "The video indexer account name."
  value       = jsondecode(azurerm_resource_group_template_deployment.vi.output_content).accountName.value
}

output "video_indexer_account_id" {
  description = "The video indexer account id."
  value       = jsondecode(azurerm_resource_group_template_deployment.vi.output_content).accountId.value
}

output "media_storage_account_name" {
  description = "The media storage account name."
  value       = azurerm_storage_account.media_storage.name
}

output "media_storage_resource_id" {
  description = "The media storage resource id."
  value       = azurerm_storage_account.media_storage.id
}

output "media_services_account_name" {
  description = "The media services account name."
  value       = azurerm_media_services_account.media_services.name
}

output "media_services_resource_id" {
  description = "The media services resource id."
  value       = azurerm_media_services_account.media_services.id
}
