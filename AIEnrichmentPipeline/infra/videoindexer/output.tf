output "account_id" {
  value = shell_script.videoindexer_account.output["id"]
}

output "sp_name" {
  value = azuread_application.vi.name
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

output "resource_group_name" {
  value = azurerm_media_services_account.media.resource_group_name
}
