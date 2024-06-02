param location string = resourceGroup().location

@description('Storage Account Name')
param storageAccountName string = 'pstsintstorage'
@description('Video Indexer Account Name')
param videoIndexerAccountName string = 'pe-ts-int7'
@description('Private Endpoint Name')
var privateEndpointName  = '${videoIndexerAccountName}-pe'

module videoIndexer 'videoIndexer.bicep' = {
  name: 'videoIndexer.bicep'
  params: {
    location: location
    storageAccountName: storageAccountName
    videoIndexerAccountName: videoIndexerAccountName
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
    privateEndpointName: privateEndpointName
    privateLinkResource: videoIndexer.outputs.videoIndexerResourceId
  }
  dependsOn: [
    videoIndexer
  ]
}
