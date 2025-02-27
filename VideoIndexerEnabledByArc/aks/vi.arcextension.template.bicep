
param accountId string = '<enter_vi_account_id>'
param videoIndexerEndpointUri string = '<enter_endpoint_uri>'
param arcConnectedClusterName string = '<enter_arc_cluster_name>'
param extensionName string = 'videoindexer'
param useGpuForSummarization bool = false
param nodeSelectorForSummarization object = { }
param tolerationsKeyForGpu string = 'nvidia.com/gpu'

var storageClass = 'azurefile-csi'

var extensionConfigProperties = {
  'videoIndexer.endpointUri': videoIndexerEndpointUri
  'videoIndexer.accountId': accountId
  'storage.storageClass': storageClass
  'storage.accessMode': 'ReadWriteMany'
  'ViAi.gpu.enabled': string(useGpuForSummarization)
  'ViAi.gpu.tolerations.key': tolerationsKeyForGpu
}

var extensionConfigPropertiesWithSelector = reduce(items(nodeSelectorForSummarization), extensionConfigProperties, (cur, next) => union(cur, {'ViAi.gpu.nodeSelector.${next.key}': next.value}) )

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
    autoUpgradeMinorVersion: false
    scope: {
      cluster: {}
    }
    configurationSettings: extensionConfigPropertiesWithSelector
  }
}

output result string = extension.properties.provisioningState
