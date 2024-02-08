@minLength(3)
param videoIndexerPrefix string

param location string
param storageAccountName string
var videoIndexerAccountName = '${videoIndexerPrefix}vi'

@description('Storage Blob Data Contributor Role Id')
var storageBlobDataContributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
resource videoIndexerAccount 'Microsoft.VideoIndexer/accounts@2024-01-01' = {
  name: videoIndexerAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageServices: {
      resourceId: storageAccount.id
    }
  }
}

@description('Grant video Indexer Identity the BlobDataContributor role to the Storage Account')
resource vi_mediaservices_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(videoIndexerAccountName, storageAccountName, 'StorageBlobDataContributorRoleAssignment')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: videoIndexerAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: storageAccount
}

output videoIndexerPrincipalId string = videoIndexerAccount.identity.principalId
