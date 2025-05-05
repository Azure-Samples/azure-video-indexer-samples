param accountId string = '<enter_vi_account_id>'
param videoIndexerEndpointUri string = '<enter_endpoint_uri>'
param arcConnectedClusterName string = '<enter_arc_cluster_name>'
param extensionName string = '<extension_name>'
param releaseTrain string = 'preview'
param version string
param useGpuForSummarization bool = false
param nodeSelectorForSummarization object = { }
param nodeSelectorForLiveSummarization object = { }
param deepstreamNodeSelector string = ''
param tolerationsKeyForGpu string = 'nvidia.com/gpu'
param liveSummarizationEnabled bool = true

var storageClass = 'azurefile-csi'

var baseConfigProperties = {
  'videoIndexer.endpointUri': videoIndexerEndpointUri
  'videoIndexer.accountId': accountId
  'videoIndexer.mediaFilesEnabled': string(true)
  'videoIndexer.liveStreamEnabled': string(true)
  'mediaServerStreams.enabled': string(true)
  'storage.storageClass': storageClass
  'storage.accessMode': 'ReadWriteMany'
  'ViAi.gpu.enabled': string(useGpuForSummarization)
  'ViAi.gpu.tolerations.key': tolerationsKeyForGpu
  'ViAi.LiveSummarization.enabled': string(liveSummarizationEnabled)
}

var summarizationNodeSelectorProps = reduce(
  items(nodeSelectorForSummarization),
  {},
  (cur, next) => union(cur, {'ViAi.gpu.nodeSelector.${next.key}': next.value})
)

var liveSummarizationNodeSelectorProps = reduce(
  items(nodeSelectorForLiveSummarization),
  {},
  (cur, next) => union(cur, {'ViAi.LiveSummarization.gpu.nodeSelector.${next.key}': next.value})
)

var deepstreamNodeSelectorProps = !empty(deepstreamNodeSelector) && deepstreamNodeSelector != ' ' ? {
  'viai.deepstream.nodeselector': deepstreamNodeSelector
} : {}

var extensionConfigPropertiesWithSelector = union(
  baseConfigProperties,
  summarizationNodeSelectorProps,
  liveSummarizationNodeSelectorProps,
  deepstreamNodeSelectorProps
)
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
    releaseTrain: releaseTrain
    version: version
    scope: {
      cluster: {}
    }
    configurationSettings: extensionConfigPropertiesWithSelector
  }
}

output result string = extension.properties.provisioningState
