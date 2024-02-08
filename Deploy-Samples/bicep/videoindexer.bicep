@minLength(3)
param videoIndexerPrefix string

param location string
param storageAccountName string
var videoIndexerAccountName = '${videoIndexerPrefix}vi'



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

output videoIndexerPrincipalId string = videoIndexerAccount.identity.principalId
