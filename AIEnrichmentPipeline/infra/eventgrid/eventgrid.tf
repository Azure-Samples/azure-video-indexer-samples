resource "azurerm_eventgrid_system_topic" "corestoragesystemtopic" {
  name                   = "corestoragesystemtopic"
  resource_group_name    = var.shared_env.rg.name
  location               = var.shared_env.rg.location
  source_arm_resource_id = var.source_arm_resource_id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "corestoragesubscription" {
  name                = "corestoragesubscription"
  system_topic        = azurerm_eventgrid_system_topic.corestoragesystemtopic.name
  resource_group_name = var.shared_env.rg.name

  azure_function_endpoint {
    function_id = var.function_id
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/input"
    case_sensitive      = false
  }
}
