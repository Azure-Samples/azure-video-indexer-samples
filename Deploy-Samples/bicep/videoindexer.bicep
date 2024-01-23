@minLength(3)
param videoIndexerPrefix string

param location string
param stoargeAccountId string 
var mediaServicesAccountName = '${videoIndexerPrefix}ms'
var videoIndexerAccountName = '${videoIndexerPrefix}vi'

@description('Contributor role definition ID')
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'


resource media_mediaService 'Microsoft.Media/mediaservices@2021-06-01' = {
  name: mediaServicesAccountName
  location: location
  properties: {
    storageAccounts: [
      {
        id: stoargeAccountId
        type: 'Primary'
      }
    ]
  }
}

resource media_videoIndexerAccount 'Microsoft.VideoIndexer/accounts@2022-08-01' = {
  name: videoIndexerAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    mediaServices: {
      resourceId: media_mediaService.id
    }
  }
}

@description('Grant video Indexer Principal Id Contributor role to the Media Services')
resource vi_mediaservices_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(videoIndexerAccountName, mediaServicesAccountName, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: media_videoIndexerAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: media_mediaService
}

output videoIndexerAccountName string = media_videoIndexerAccount.name
output videoIndexerPrincipalId string = media_videoIndexerAccount.identity.principalId
output mediaServiceAccountName string = media_mediaService.name
output videoIndexerAccountId string = media_videoIndexerAccount.properties.accountId
