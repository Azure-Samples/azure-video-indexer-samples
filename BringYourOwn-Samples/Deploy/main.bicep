param location string = resourceGroup().location

@description('The prefix to use for all resources')
@minLength(3)
param resourceNamePrefix string

@description('Deployment name/id')
param deploymentNameId string = '0000000000'

@description('The Computer Vision endpoint')
param computerVisionEndpoint string
@description('The Computer Vision API Key')
param computerVisionKey string
@description('The Computer Vision Custom Model Name')
param computerVisionCustomModelName string

var storageAccountName = '${envResourceNamePrefix}sa'
var functionAppName = '${envResourceNamePrefix}-asp'
var eventHubNamespaceName = '${envResourceNamePrefix}-eventhub'
var eventHubName = 'vilogs'
var envResourceNamePrefix = toLower(resourceNamePrefix)

/* Storage */
module storageAccount 'storage.bicep' = {
  name: '${deploymentNameId}-appservice-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

/* event Hubs */
module eventHubs 'eventsHub.bicep' = {
  name: '${deploymentNameId}-eventsHub'
  params: {
    location: location
    eventHubNamespaceName: eventHubNamespaceName
    eventHubName: eventHubName
  }
}

/* Video Indexer */
module videoIndexer 'videoindexer.bicep' = {
  name: '${deploymentNameId}-videoIndexer'
  params: {
    storageAccountName: storageAccountName
    videoIndexerPrefix: envResourceNamePrefix
    location: location
  }
  dependsOn: [
    storageAccount
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
    storageAccountName: storageAccountName
    storageAccountKey: storageAccount.outputs.storageAccountKey
    viAccountId: videoIndexer.outputs.videoIndexerAccountId
    eventsHubConnectionString: eventHubs.outputs.eventHubNamespaceConnectionString
    computerVisionEndpoint: computerVisionEndpoint
    computerVisionKey: computerVisionKey
    computerVisionCustomModelName: computerVisionCustomModelName
  }
  dependsOn: [
    eventHubs
    storageAccount
    videoIndexer
  ]
}

/* Role Assignment */
module appSettingsRoleAssignments 'role-assignment.bicep' = {
  name: '${deploymentNameId}-roleAssignment'
  params: {
    appServicePrincipalId: viapp_function.outputs.appServicePrincipalId
    eventHubNamespace: eventHubNamespaceName
    storageAccountName:  storageAccountName
    videoIndexerPrincipalId: videoIndexer.outputs.videoIndexerPrincipalId
  }
  dependsOn: [
    videoIndexer
    eventHubs
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
    videoIndexer
    appSettingsRoleAssignments
    eventHubs
  ]
}

/* define outputs */

output functionAppName string = functionAppName
output eventHubNamespaceName string = eventHubNamespaceName
output videoIndexerAccountName string = videoIndexer.outputs.videoIndexerAccountName
