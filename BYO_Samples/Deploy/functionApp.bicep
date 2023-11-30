param resourcePrefix string
param location string
param deploymentNameId string
param appInsightsKey string
param storageAccountName string
param viAccountId string

@description('Storage Account Access Key')
@secure()
param storageAccountKey string
param functionAppName string

param computerVisionEndpoint string
param computerVisionKey string
param computerVisionCustomModelName string


param linuxFxVersion string = 'DOTNET|4.27.5.5'

@description('Event Hub Connection String to place as ENV Variable')
param eventsHubConnectionString string

resource azHostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'linux'
  sku: {
    tier: 'Standard'
    name: 'S2'
    size: 'S2'
    family: 'S'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource viFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: '${resourcePrefix}-app'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: azHostingPlan.id
    clientAffinityEnabled: true
    reserved: true
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: 'DOTNET|${linuxFxVersion}'
    }
  }
}


// set the app settings on function app's deployment slots
module appService_appSettings 'app-config.bicep' = {
  name: '${deploymentNameId}-appservice-config'
  params: {
    applicationInsightsInstrumentationKey: appInsightsKey
    storageAccountName: storageAccountName
    storageAccountAccessKey: storageAccountKey
    resorucePrefix: resourcePrefix
    viAccountId: viAccountId
    eventsHubConnectionString: eventsHubConnectionString
    csVisionEndpoint: computerVisionEndpoint
    csVisionAPIKey: computerVisionKey
    csVisionCustomModelName: computerVisionCustomModelName
  }
  dependsOn: [
    viFunctionApp
  ]
}

output functionAppId string = viFunctionApp.id
output appServicePrincipalId string = viFunctionApp.identity.principalId
