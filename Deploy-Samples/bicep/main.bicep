param location string = resourceGroup().location

@description('The prefix to use for all resources')
@minLength(3)
param resourceNamePrefix string

@description('Deployment name/id')
param deploymentNameId string = '0000000000'

@description('The principal Id of user/System MI or App to grant permission on the VI Event hub logs')
param appServicePrincipalId string

var envResourceNamePrefix = toLower(resourceNamePrefix)
var storageAccountName = '${envResourceNamePrefix}sa'
var eventHubNamespaceName = '${envResourceNamePrefix}-eventhub'
var eventHubName = 'vilogs'

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

/* Role Assignment */
module appSettingsRoleAssignments 'role-assignment.bicep' = {
  name: '${deploymentNameId}-roleAssignment'
  params: {
    appServicePrincipalId: appServicePrincipalId
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

output eventHubNamespaceName string = eventHubNamespaceName
output videoIndexerAccountName string = viapp_videoIndexer.outputs.videoIndexerAccountName
