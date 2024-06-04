
param accountResourceId string = '<enter_vi_account_resource_id>'
param accountId string = '<enter_vi_account_id>'
param videoIndexerEndpointUri string = '<enter_endpoint_uri>'
param arcConnectedClusterName string = '<enter_arc_cluster_name>'
param identityId string = '<enter_identity_resource_id>'

param forceUpdateTag string = utcNow()
param location string = resourceGroup().location

var storageClass = 'azurefile-csi'
var extensionName = 'videoindexer'
var tags  = {
  CreatedBy: 'VI Azure Arc Samples'
}

var createDependentResoruceUri = 'https://raw.githubusercontent.com/Azure-Samples/azure-video-indexer-samples/master/VideoIndexerEnabledByArc/aks/createDependencies.ps1'

resource CreateDependentResouces 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'CreateDependentResouces'
  location: location
  tags: tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    forceUpdateTag: forceUpdateTag
    azPowerShellVersion: '8.3'
    primaryScriptUri: createDependentResoruceUri
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'
    arguments: '-accountResourceId ${accountResourceId}'
  }
}

resource connectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-01-01' existing = {
  name: arcConnectedClusterName

}
resource extension 'Microsoft.KubernetesConfiguration/extensions@2022-11-01' = {
  name: extensionName
  scope: connectedCluster
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.videoindexer'
    autoUpgradeMinorVersion: true
    scope: {
      cluster: {}
    }
    configurationSettings: {
      'videoIndexer.endpointUri': videoIndexerEndpointUri
      'videoIndexer.accountId': accountId
      'storage.storageClass': storageClass
      'storage.accessMode': 'ReadWriteMany'
    }
    configurationProtectedSettings: {
      'translate.endpointUri': CreateDependentResouces.properties.outputs.translatorCognitiveServicesEndpoint
      'translate.secret': CreateDependentResouces.properties.outputs.translatorCognitiveServicesPrimaryKey
      'speech.endpointUri': CreateDependentResouces.properties.outputs.speechCognitiveServicesEndpoint
      'speech.secret': CreateDependentResouces.properties.outputs.speechCognitiveServicesPrimaryKey
      'ocr.endpointUri': CreateDependentResouces.properties.outputs.ocrCognitiveServicesEndpoint
      'ocr.secret': CreateDependentResouces.properties.outputs.ocrCognitiveServicesPrimaryKey
    }
  }
}

output result string = CreateDependentResouces.properties.outputs.result
