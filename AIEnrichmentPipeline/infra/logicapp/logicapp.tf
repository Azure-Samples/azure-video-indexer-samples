locals {
  arm_file_path = "${path.module}/../../logicapp/${var.workflow_name}/armtemplate.json"
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

// Create an instance of logic app and configure the tags
resource "azurerm_logic_app_workflow" "logicapp" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags

  name = var.workflow_name
  lifecycle {
    ignore_changes = [
      # Ignore changes to parameters as otherwise we will break the $connections
      parameters,
      tags
    ]
  }
}

// Deploy the ARM template to configure the workflow in the logicapp

data "template_file" "workflow" {
  template = file(local.arm_file_path)
}

resource "azurerm_template_deployment" "workflow" {
  depends_on = [azurerm_logic_app_workflow.logicapp]

  resource_group_name = var.shared_env.rg.name
  parameters = merge({
    "workflowName" = var.workflow_name,
    "location"     = var.shared_env.rg.location
  }, var.parameters)

  template_body = data.template_file.workflow.template

  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "workflow-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"

}

resource "azurerm_monitor_diagnostic_setting" "pipeline-diagnostic" {
  name                       = "logic-app${random_string.random.result}"
  target_resource_id         = azurerm_logic_app_workflow.logicapp.id
  log_analytics_workspace_id = var.law_id

  log {
    category = "WorkflowRuntime"
    enabled  = true
    retention_policy {
      days    = 1
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      days    = 1
      enabled = true
    }
  }
}
