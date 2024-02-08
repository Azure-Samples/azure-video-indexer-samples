@minLength(3)
param videoIndexerPrefix string

param location string

var videoIndexerAccountName = '${videoIndexerPrefix}vi'
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
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


output videoIndexerAccountName string = videoIndexerAccount.name
output videoIndexerPrincipalId string = videoIndexerAccount.identity.principalId
output videoIndexerAccountId string = videoIndexerAccount.properties.accountId
