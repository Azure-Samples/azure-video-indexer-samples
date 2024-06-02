@secure()
param servicePrincipalObjectId string
param storageAccountName string

@description('Storage Blob Data Contributor Role Id')
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing= {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccount.id, servicePrincipalObjectId, 'Storage Blob Data Contributor') 
  scope: storageAccount 
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId) 
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
  }
}


