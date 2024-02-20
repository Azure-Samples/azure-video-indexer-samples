param location string = resourceGroup().location

@description('Storage Account Name')
param storageAccountName string
@description('Video Indexer Account Name')
param videoIndexerAccountName string

module videoIndexer 'videoIndexer.bicep' = {
  name: 'videoIndexer.bicep'
  params: {
    location: location
    storageAccountName: storageAccountName
    videoIndexerAccountName: videoIndexerAccountName
  }
}

// Role Assignment must be on a separate resource 
module roleAssignment 'role-assignment.bicep' = {
  name: 'grant-storage-blob-data-contributor'
  params: {
    servicePrincipalObjectId: videoIndexer.outputs.servicePrincipalId
    storageAccountName: storageAccountName
  }
  dependsOn: [
    videoIndexer
  ]
}
