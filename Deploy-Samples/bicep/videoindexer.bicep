@minLength(3)
param videoIndexerPrefix string

param location string
var videoIndexerAccountName = '${videoIndexerPrefix}vi'

@description('Storage Blob Data Contributor role definition ID')
var contributorRoleDefinitionId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'


param storageAccountName string

resource viStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource media_videoIndexerAccount 'Microsoft.VideoIndexer/accounts@2024-01-01' = {
  name: videoIndexerAccountName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/24237b72-8546-4da5-b204-8c3cb76dd930/resourcegroups/tspoc34-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tspoc34mi': {}
    }
  }
  properties: {
    storageServices: {
      resourceId: viStorageAccount.id
    }
  }
}


@description('Grant video Indexer Account Principal Id Contributor role to the Storage Account')
resource vi_mediaservices_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(videoIndexerAccountName, videoIndexerAccountName, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: 'add73586-353c-4479-858a-e1d9b49d6190'
    principalType: 'ServicePrincipal'
  }
  scope: viStorageAccount
}


output videoIndexerAccountName string = media_videoIndexerAccount.name
//output videoIndexerPrincipalId string = media_videoIndexerAccount.identity.principalId
output viStorageAccountId string = viStorageAccount.id
output videoIndexerAccountId string = media_videoIndexerAccount.properties.accountId
