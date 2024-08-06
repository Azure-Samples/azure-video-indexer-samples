param location string = resourceGroup().location

param resourcePrefix string = '10spades'
var storageAccountNameUnformatted  = '${resourcePrefix}sa'
var storageAccountName = toLower(replace(storageAccountNameUnformatted, '-', ''))
var videoIndexerAccountName = '${resourcePrefix}-vi'
var privateEndpointName  = '${resourcePrefix}-pe2'
var vnetName = '${resourcePrefix}-vnet'
var publicNetworkAccess = 'Disabled'
var deployPrivteEndpoint = true


module videoIndexer 'videoIndexer.bicep' = {
  name: 'videoIndexer.bicep'
  params: {
    location: location
    storageAccountName: storageAccountName
    videoIndexerAccountName: videoIndexerAccountName
    publicNetworkAccess: publicNetworkAccess
  }
}

 // Role Assignment must be on a separate resource 
module roleAssignment 'roleAssignment.bicep' = {
  name: 'grant-storage-blob-data-contributor'
  params: {
    servicePrincipalObjectId: videoIndexer.outputs.servicePrincipalId
    storageAccountName: storageAccountName
  }
  dependsOn: [
    videoIndexer
  ]
}

module privateEndpoint 'privateEndpoint.bicep' = {
  name: 'privateEndpoint.bicep'
  params: {
    location: location
    vnetName: vnetName
    privateEndpointName: privateEndpointName
    privateLinkResource: videoIndexer.outputs.videoIndexerResourceId
    deployPrivateEndpoint: deployPrivteEndpoint
  }
  dependsOn: [
    videoIndexer
  ]
}
