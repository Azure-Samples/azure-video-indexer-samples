param location string
param storageAccountName string

resource azStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

var azStorageAccountPrimaryAccessKey = azStorageAccount.listKeys().keys[0].value
output storageAccountId string = azStorageAccount.id
output storageAccountKey string = azStorageAccountPrimaryAccessKey

