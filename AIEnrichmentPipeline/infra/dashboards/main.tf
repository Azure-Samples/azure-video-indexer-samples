data "template_file" "dash_template" {
  template = "${file("${path.module}/dashboard.tpl")}"
  vars = {
    subscriptionid = var.parameters.subscriptionid
    rgname         = var.shared_env.rg.name
    lawid          = var.parameters.lawid
    appinsightsid  = var.parameters.appinsightsid
  }
}

resource "azurerm_dashboard" "enrichmentpipeline_board" {
  name                 = "enrichmentpipeline-dashboard"
  resource_group_name  = var.shared_env.rg.name
  location             = var.shared_env.rg.location
  tags                 = var.shared_env.tags
  dashboard_properties = data.template_file.dash_template.rendered
}

data "template_file" "admin_dash_template" {
  template = "${file("${path.module}/admin_dashboard.tpl")}"
  vars = {
    subscriptionid = var.parameters.subscriptionid
    rgname         = var.shared_env.rg.name
    lawid          = var.parameters.lawid
    appinsightsid  = var.parameters.appinsightsid
  }
}

resource "azurerm_dashboard" "enrichmentpipeline_admin_board" {
  name                 = "enrichmentpipeline-admin-dashboard"
  resource_group_name  = var.shared_env.rg.name
  location             = var.shared_env.rg.location
  tags                 = var.shared_env.tags
  dashboard_properties = data.template_file.admin_dash_template.rendered
}
