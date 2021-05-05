output "function_details" {
  sensitive = false
  value = {
    defaulthostname = azurerm_function_app.functions.default_hostname
    name            = azurerm_function_app.functions.name
    resourcegroup   = azurerm_function_app.functions.resource_group_name
    baseuri         = "https://${azurerm_function_app.functions.default_hostname}",
    id              = azurerm_function_app.functions.id
  }
}

output "function_host_keys" {
  value = data.azurerm_function_app_host_keys.functions_host_keys
}
