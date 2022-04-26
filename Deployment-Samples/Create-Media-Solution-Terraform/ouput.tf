output "account_id" {
  value = jsondecode(azurerm_resource_group_template_deployment.vi.output_content).avam_account_id.value
}

output "media_storage_account_name" {
  value = azurerm_storage_account.media_storage.name
}

output "media_storage_account_id" {
  value = azurerm_storage_account.media_storage.id
}

output "media_services_account_id" {
  value = azurerm_media_services_account.media.id
}

output "media_services_account_name" {
  value = azurerm_media_services_account.media.name
}