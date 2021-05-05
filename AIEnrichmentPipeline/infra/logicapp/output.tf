output "logic_app_details" {
  sensitive = true
  value = {
    logic_app_uri          = lookup(azurerm_template_deployment.workflow.outputs, "logic_app_uri", "") != "" ? "${azurerm_template_deployment.workflow.outputs["logic_app_uri"]}" : azurerm_logic_app_workflow.logicapp.id
    id                     = azurerm_logic_app_workflow.logicapp.id
    name                   = azurerm_logic_app_workflow.logicapp.name
    resourcegroup          = azurerm_logic_app_workflow.logicapp.resource_group_name
    logic_app_outbound_ips = concat(azurerm_logic_app_workflow.logicapp.workflow_outbound_ip_addresses, azurerm_logic_app_workflow.logicapp.connector_outbound_ip_addresses, azurerm_logic_app_workflow.logicapp.workflow_endpoint_ip_addresses, azurerm_logic_app_workflow.logicapp.connector_endpoint_ip_addresses)
  }
}