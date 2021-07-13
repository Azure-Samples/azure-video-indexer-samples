resource "azurerm_cognitive_account" "corecomputervision" {
  name                = "corecomputervision${random_string.random.result}"
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  kind                = "ComputerVision"
  sku_name            = "S1"
}

resource "azurerm_cognitive_account" "coretextanalytics" {
  name                = "coretextanalytics${random_string.random.result}"
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  kind                = "TextAnalytics"
  sku_name            = "S"
}

resource "azurerm_cognitive_account" "coretexttranslation" {
  name                = "coretexttranslation${random_string.random.result}"
  location            = var.shared_env.rg.location
  resource_group_name = var.shared_env.rg.name
  kind                = "TextTranslation"
  sku_name            = "S1"
}
