param eventHubNamespaceName string
param eventHubName string
param location string


resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 2
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
    status: 'Active'
  }
}

resource eventHubNamespaceName_eventHubName_ListenSend 'Microsoft.EventHub/namespaces/authorizationRules@2021-01-01-preview' existing = {
  parent: eventHubNamespace
  name: 'RootManageSharedAccessKey'
}

// Determine our connection string
var eventHubNamespaceConnectionString = eventHubNamespaceName_eventHubName_ListenSend.listKeys().primaryConnectionString

// Output our variables
output eventHubNamespaceConnectionString string = eventHubNamespaceConnectionString
output eventHubName string = eventHubName
