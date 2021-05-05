# Enrichment Pipeline Shared Dashboard

This module will deploy a single, shared, custom Azure dashboard for the project. (See [https://docs.microsoft.com/en-us/azure/azure-monitor/learn/tutorial-app-dashboards](https://docs.microsoft.com/en-us/azure/azure-monitor/learn/tutorial-app-dashboards) for further details around custom dashboards).

To view the dashboard you can create a deployment and find `enrichmentpipeline-dashboard` under the list of resources under the resource group in which the deployment was created.

(For details See Wiki - TODO: not there yet)

## Creation

The definition of the dashboard looks like this:

```terraform
resource "azurerm_dashboard" "enrichmentpipeline_board" {
  name                 = "enrichmentpipeline_dashboard"
  resource_group_name  = var.shared_env.rg.name
  location             = var.shared_env.rg.location
  tags                 = var.shared_env.tags
  dashboard_properties = data.template_file.dash_template.rendered
}
```

where the `dasboard_properties` represents a rendered file template and the file template is `data` defined like this:

```terraform
data "template_file" "dash_template" {
  template = "${file("${path.module}/dashboard.tpl")}"
  vars = {
    subscriptionid = var.parameters.subscriptionid
    rgname         = var.shared_env.rg.name
  }
}
```

Which is comprised of a `dashboard.tpl` file along with some variables passed to the template.

## Editing

(For details See Wiki - TODO: not there yet)