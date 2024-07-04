param location string = resourceGroup().location

@description('Storage Account Name')
param storageAccountName string
@description('Video Indexer Account Name')
param videoIndexerAccountName string

@description('Storage Account Kind')
var storageKind = 'StorageV2'
@description('Storage Account Sku')
var storageSku = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: storageKind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
  }
  sku: {
    name: storageSku
  }
}

resource videoIndexer 'Microsoft.VideoIndexer/accounts@2023-11-01-preview' = {
  name: videoIndexerAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageServices: {
      resourceId: storageAccount.id
    }
    publicNetworkAccess: 'Enabled'
  }
}

output storageAccountName string = storageAccount.name
output accountName string = videoIndexer.name
output servicePrincipalId string = videoIndexer.identity.principalId
output videoIndexerResourceId string = videoIndexer.id
