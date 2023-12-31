param videoIndexerAccountName string
param eventHubName string
param eventHubNamespace string

resource media_videoIndexerAccount 'Microsoft.VideoIndexer/accounts@2022-08-01' existing = {
  name: videoIndexerAccountName
}  

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vilogs'
  scope: media_videoIndexerAccount
  properties: {
    eventHubAuthorizationRuleId: resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespace, 'RootManageSharedAccessKey')
    eventHubName: eventHubName
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
