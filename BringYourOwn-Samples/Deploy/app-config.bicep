param applicationInsightsInstrumentationKey string
param storageAccountName string
param storageAccountAccessKey string
param resorucePrefix string 
param viAccountId string

//Compute Vision Resource
param csVisionEndpoint string
param csVisionCustomModelName string
param csVisionAPIKey string

var viAccountName = '${resorucePrefix}vi'
var viAccountRg = '${resorucePrefix}-rg'
var functionAppName = '${resorucePrefix}-app'


@description('Value of "APP_CONFIGURATION_LABEL" appsetting for production slot')
param appConfiguration_appConfigLabel_value_production string = 'production'

@description('Events Hub connection string')
param eventsHubConnectionString string 

/* base app settings for all accounts */
var BASE_SLOT_APPSETTINGS = {
  APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsightsInstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${applicationInsightsInstrumentationKey}'
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountAccessKey}'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  WEBSITE_CONTENTSHARE: toLower(storageAccountName)
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountAccessKey}'
  SUBSCIPTION_ID: subscription().subscriptionId
  VI_RESOURCE_GROUP: viAccountRg
  VI_ACCOUNT_NAME: viAccountName
  VI_ACCOUNT_ID: viAccountId
  API_ENDPOINT: 'https://api.videoindexer.ai'
  VI_LOCATION: 'eastus'
  CS_VISION_ENDPOINT: csVisionEndpoint
  CS_VISION_CUSTOM_MODEL_NAME: csVisionCustomModelName
  CS_VISION_API_KEY: csVisionAPIKey
  EHCONNECTION: eventsHubConnectionString
  DETECT_OBJECT_CLASS: 'Car'
}

/* update production slot with unique settings */
var PROD_SLOT_APPSETTINGS = {
  APP_CONFIGURATION_LABEL: appConfiguration_appConfigLabel_value_production
}

@description('Set app settings on production slot')
resource functionAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: '${functionAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, PROD_SLOT_APPSETTINGS)
}
