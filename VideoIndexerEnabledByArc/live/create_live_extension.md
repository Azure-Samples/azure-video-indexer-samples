# Video Indexer Arc Extension


### Step 1 - Create Azure Arc Video Indexer Extension using CLI

The following parameters will be used as input to the extension creation command:

| Parameter | Default | Description
|-----------|---------|-------------
| release-namespace | default | The kubernetes namespace which the extension will be installed into
| cluster-name | | The kubernetes azure arc instance name
| resource-group | | The kubernetes azure arc resource group name
| version | latest | Video Indexer Extension version
| videoIndexer.accountId |  | Video Indexer Account Id
| videoIndexer.endpointUri |  | Video Indexer Dns Name to be used as the Portal endpoint
| ViAi.gpu.tolerations.key | | the default toleration in which gpu 
| videoIndexer.mediaFilesEnabled | true | Enable media files upload 
| ViAi.gpu.nodeSelector.workload | | The gpu for media files summarization
| videoIndexer.liveStreamEnabled | false | Enable live streaming
| ViAi.LiveSummarization.enabled | false | Enable live summarization on the recordings
| ViAi.LiveSummarization.gpu.nodeSelector.workload | | The node selector for live summarization 
* 
```bash
az k8s-extension create --name $extension_name --extension-type "Microsoft.videoIndexer" --scope cluster \
  --release-namespace "video-indexer" \
  --cluster-name $cluster_name \
  --resource-group $cluster_resource_group \
  --cluster-type "connectedClusters" \
  --version $version \
  --release-train "preview" \
  --auto-upgrade-minor-version "false" \
  --config "videoIndexer.accountId=$account_id" \
  --config "videoIndexer.endpointUri=$endpoint" \
  --config AI.nodeSelector."beta\\.kubernetes\\.io/os"=linux \
  --config "storage.storageClass=azurefile-csi" \
  --config "storage.accessMode=ReadWriteMany" \
  --config "ViAi.gpu.enabled=true" \
  --config "ViAi.gpu.tolerations.key=nvidia.com/gpu" \
  --config videoIndexer.liveStreamEnabled=true \
  --config videoIndexer.mediaFilesEnabled=true \
  --config "ViAi.LiveSummarization.enabled=true" \
  --config "ViAi.LiveSummarization.gpu.nodeSelector.workload=summarization" \
  --config "ViAi.gpu.nodeSelector.workload=summarization"

```

There are some additional Parameters that can be used in order to have a fine grain control on the extension creation

| Parameter | Default | Description
|-----------|---------|-------------
| AI.nodeSelector | - | The node Selector label on which the AI Pods (speech and translate)  will be assigned to
resource.requests.mem
| videoIndexer.webapi.resources.requests.cpu | 0.5 | The request number of cores for the web api pod
| videoIndexer.webapi.resources.requests.mem | 4Gi | The request memory capacity for the web api pod
| videoIndexer.webapi.resources.limits.cpu | 1 | The limits number of cores for the web api pod
| videoIndexer.webapi.resources.limits.mem | 6Gi | The limits memory capacity for the web api pod
| videoIndexer.webapi.resources.limits.mem | 6Gi | The limits memory capacity for the web api pod
| storage.storageClass | "" | The storage class to be used
| storage.useExternalPvc | false | determines whether an external PVC is used. if true, the VideoIndexer PVC will not be installed

example deploy script :

```bash
az k8s-extension create --name videoindexer \
    --extension-type Microsoft.videoindexer \
    .......

    --config AI.nodeSelector."beta\\.kubernetes\\.io/os"=linux
    --config "videoIndexer.webapi.resources.requests.mem=4Gi"\
    --config "videoIndexer.webapi.resources.limits.mem=8Gi"\
    --config "videoIndexer.webapi.resources.limits.cpu=1"\
    --config "storage.storageClass=azurefile-csi" 

```



### Step 2 - Update Azure Arc Video Indexer Extension using CLI
Add any of the above parameters with their new values if you want to change those in the below example im changing the endpoint of the extension
```bash
az k8s-extension update --name $extension_name --extension-type "Microsoft.videoIndexer" --scope cluster \
  --release-namespace "video-indexer" \
  --cluster-name $cluster_name \
  --resource-group $cluster_resource_group \
  --cluster-type "connectedClusters" \
  --version $version \
  --release-train "preview" \
  --config "videoIndexer.endpointUri=$endpoint"

```  
