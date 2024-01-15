param location string = resourceGroup().location

@description('The prefix to use for all resources')
@minLength(3)
param resourceNamePrefix string

@description('Deployment name/id')
param deploymentNameId string = '0000000000'


var storageAccountName = '${envResourceNamePrefix}sa'
var functionAppName = '${envResourceNamePrefix}-asp'
var eventHubNamespaceName = '${envResourceNamePrefix}-eventhub'
var eventHubName = 'vilogs'
var envResourceNamePrefix = toLower(resourceNamePrefix)

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
module media_videoIndexer 'videoindexer.bicep' = {
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

/* Role Assignment */
module appSettingsRoleAssignments 'role-assignment.bicep' = {
  name: '${deploymentNameId}-roleAssignment'
  params: {
    principalId: media_videoIndexer.outputs.videoIndexerPrincipalId
    eventHubNamespace: eventHubNamespaceName
  }
  dependsOn: [
    media_videoIndexer
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
    media_videoIndexer
    appSettingsRoleAssignments
    viapp_eventHubs
  ]
}

/* define outputs */

output functionAppName string = functionAppName
output eventHubNamespaceName string = eventHubNamespaceName
output videoIndexerAccountName string = media_videoIndexer.outputs.videoIndexerAccountName
