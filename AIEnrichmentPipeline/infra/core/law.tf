resource "azurerm_log_analytics_workspace" "core" {
  name                = "corelaw${random_string.random.result}"
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "logicappsmngmt" {
  solution_name         = "LogicAppsManagement"
  location              = var.shared_env.rg.location
  resource_group_name   = var.shared_env.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.core.id
  workspace_name        = azurerm_log_analytics_workspace.core.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/LogicAppsManagement"
  }
}
