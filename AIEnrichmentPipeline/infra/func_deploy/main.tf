resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

locals {
  plan_tier    = "ElasticPremium"
  plan_size    = "EP1"
  plan_kind    = "elastic"
  path_to_func = "../functions/releases/${var.function_name}.zip"
  upload_name  = "${base64encode(filesha256("${local.path_to_func}"))}${var.function_name}.zip"

  # Plan and function name contains the tier and size to correctly trigger destroying of it's functions
  # when these property changes. This works as the name fields are "ForceNew" this ensures the destory and recreation of funcs/plans
  # when the kind or tier is changed. 
  # This works around the bug here: https://github.com/terraform-providers/terraform-provider-azurerm/issues/5990
  function_name = "${var.function_name}-${local.plan_tier}${local.plan_kind}${random_string.random.result}"


  # If a user taints and redeploys the function app or webapp the VNET needs to run
  # to configure the VNET on the newly deployed app. However, the taint won't trigger this 
  # because none of the inputs have changed. To work around this we have added a `force_redeploy` field
  # which needs to be passed the `md5(azurerm_function_app.app.site_credentials.password)` as these
  # change after a redeployment
  force_vnet_redeploy = md5(azurerm_function_app.functions.site_credential[0].password)
}

resource "azurerm_storage_blob" "appcode" {
  name                   = local.upload_name
  storage_account_name   = var.releases_storage_account_name
  storage_container_name = var.releases_container_name
  type                   = "Block"
  source                 = local.path_to_func
}

resource "azurerm_function_app" "functions" {
  name     = local.function_name
  location = var.shared_env.rg.location
  tags     = var.shared_env.tags

  resource_group_name        = var.shared_env.rg.name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = var.releases_storage_account_name
  storage_account_access_key = var.releases_storage_account_key
  version                    = "~3"

  site_config {
    use_32_bit_worker_process = false
    pre_warmed_instance_count = 1
  }

  # This takes in the app settings from the module defintion which are specific to a function 
  # and merges them with the settings we know will always be needed for any function
  app_settings = merge({
    https_only               = true
    FUNCTIONS_WORKER_RUNTIME = "dotnet"

    HASH                     = "${base64encode(filesha256("${local.path_to_func}"))}"
    WEBSITE_RUN_FROM_PACKAGE = "https://${var.releases_storage_account_name}.blob.core.windows.net/${var.releases_container_name}/${local.upload_name}${var.releases_storage_sas}"
    WEBSITE_DNS_SERVER       = "168.63.129.16"
    WEBSITE_VNET_ROUTE_ALL   = 1
  }, var.app_settings)
}

data "template_file" "arm" {
  template = "${file("${path.module}/func_vnet.arm.json")}"
}

data "azurerm_function_app_host_keys" "functions_host_keys" {
  name                = azurerm_function_app.functions.name
  resource_group_name = azurerm_function_app.functions.resource_group_name

  depends_on = [azurerm_function_app.functions]
}
