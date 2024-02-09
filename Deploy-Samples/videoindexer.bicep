param location string = resourceGroup().location


@description('Storage Account Name')
param storageAccountName string
@description('Video Indexer Account Name')
param videoIndexerAccountName string

@description('Storage Account Kind')
var storageKind = 'StorageV2'
@description('Storage Account Sku')
var storageSku = 'Standard_LRS'
@description('Storage Blob Data Contributor Role Id')
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: storageKind
  sku: {
    name: storageSku
  }
}

resource videoIndexer 'Microsoft.VideoIndexer/accounts@2024-01-01' = {
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



// Define the role assignment resource
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, storageAccountName, storageBlobDataContributorRoleId) // Deterministic GUID
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: videoIndexer.identity.principalId 
    principalType: 'ServicePrincipal' 
  }
}

