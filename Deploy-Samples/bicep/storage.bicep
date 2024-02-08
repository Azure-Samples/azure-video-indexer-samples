param location string


var azStorageAccountPrimaryAccessKey = azStorageAccount.listKeys().keys[0].value
output storageAccountId string = azStorageAccount.id
output storageAccountKey string = azStorageAccountPrimaryAccessKey

