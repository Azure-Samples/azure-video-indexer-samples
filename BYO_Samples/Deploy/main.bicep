param location string = resourceGroup().location

@description('The prefix to use for all resources')
@minLength(3)
param resourceNamePrefix string

var envResourceNamePrefix = toLower(resourceNamePrefix)

@description('Deployment name/id')
param deploymentNameId string = '0000000000'

var storageAccountName = '${envResourceNamePrefix}sa'
var functionAppName = '${envResourceNamePrefix}-asp'
var eventHubNamespaceName = '${envResourceNamePrefix}-eventhub'
var eventHubName = 'vilogs'

/* App Insights  */
module viapp_appInsights 'appinsights.bicep' = {
  name: '${deploymentNameId}-appservice-appinsights'
  params: {
    location: location
    resourcePrefix: envResourceNamePrefix
  }
}

/* Storage */
module viapp_storageAccount 'storage.bicep' = {
  name: '${deploymentNameId}-appservice-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

/* event Hubs */
module viapp_eventHubs 'eventsHub.bicep' = {
  name: '${deploymentNameId}-eventsHub'
  params: {
    location: location
    eventHubNamespaceName: eventHubNamespaceName
    eventHubName: eventHubName
  }
}

/* Video Indexer */
module viapp_videoIndexer 'videoindexer.bicep' = {
  name: '${deploymentNameId}-videoIndexer'
  params: {
    stoargeAccountId: viapp_storageAccount.outputs.storageAccountId
    videoIndexerPrefix: envResourceNamePrefix
    location: location
  }
  dependsOn: [
    viapp_storageAccount
  ]
}

/* Function App */
module viapp_function 'functionApp.bicep' = {
  name: '${deploymentNameId}-function'
  params: {
    location: location
    functionAppName: functionAppName
    deploymentNameId: deploymentNameId
    resourcePrefix: envResourceNamePrefix
    appInsightsKey: viapp_appInsights.outputs.azAppInsightsInstrumentationKey
    storageAccountName: storageAccountName
    storageAccountKey: viapp_storageAccount.outputs.storageAccountKey
    viAccountId: viapp_videoIndexer.outputs.videoIndexerAccountId
    eventsHubConnectionString: viapp_eventHubs.outputs.eventHubNamespaceConnectionString
  }
  dependsOn: [
    viapp_eventHubs
    viapp_storageAccount
    viapp_videoIndexer

  ]
}

/* Role Assignment */
module appSettingsRoleAssignments 'role-assignment.bicep' = {
  name: '${deploymentNameId}-roleAssignment'
  params: {
    appServicePrincipalId: viapp_function.outputs.appServicePrincipalId
    eventHubNamespace: eventHubNamespaceName
  }
  dependsOn: [
    viapp_videoIndexer
    viapp_eventHubs
  ]
}

/* VI Diagnostic Settings*/
module viDiagnosticsSetting 'vi-diagnostics-settings.bicep' = {
  name: '${deploymentNameId}-vi-diagnostics-settings'
  params: {
    videoIndexerAccountName: '${envResourceNamePrefix}vi'
    eventHubNamespace: eventHubNamespaceName
    eventHubName: eventHubName
  }
  dependsOn: [
    viapp_videoIndexer
    appSettingsRoleAssignments
    viapp_eventHubs
  ]
}

/* define outputs */

output appInsightsInstrumentionKey string = viapp_appInsights.outputs.azAppInsightsInstrumentationKey
output functionAppName string = functionAppName
output eventHubNamespaceName string = eventHubNamespaceName
output videoIndexerAccountName string = viapp_videoIndexer.outputs.videoIndexerAccountName
