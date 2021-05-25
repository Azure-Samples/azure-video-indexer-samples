resource "azurerm_servicebus_namespace" "importer_servicebus" {
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  tags                = var.shared_env.tags

  name = "servicebus-${random_string.random.result}"

  sku = "standard"
}


resource "azurerm_servicebus_queue" "exporter" {
  resource_group_name = var.shared_env.rg.name

  name           = "exporter"
  namespace_name = azurerm_servicebus_namespace.importer_servicebus.name

  // Lock for 5mins to reduce amount of times locks
  // have to be renewed while imports are taking place
  lock_duration = "PT5M"

  // How many times should we try to import a message which
  // is failing?
  max_delivery_count = 5

  enable_batched_operations = true
}

resource "azurerm_servicebus_queue" "trigger" {
  resource_group_name = var.shared_env.rg.name

  name           = "trigger"
  namespace_name = azurerm_servicebus_namespace.importer_servicebus.name

  // Lock for 5mins to reduce amount of times locks
  // have to be renewed while imports are taking place
  lock_duration = "PT5M"

  // How many times should we try to import a message which
  // is failing?
  max_delivery_count = 5

  enable_batched_operations = true
}
