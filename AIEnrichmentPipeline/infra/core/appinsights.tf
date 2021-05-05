resource "azurerm_application_insights" "appinsights" {
  name                = "enrichmentpipeline-appinsights"
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  application_type    = "web"
}
