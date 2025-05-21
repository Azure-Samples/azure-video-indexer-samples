# Video Indexer Enabled by Arc on Azure Local
This doc will guide you through the process of enabling Video Indexer on Azure Local.

## Infra Prerequisites
1. Azure Local cluster is up and running.
2. Kubernetes - Azure Arc enabled Kubernetes cluster is up and running.
3. Networking extension
4. Storage provisioner (disk.csi.akshci.com) set as the default storage class

## Prerequisites
Install the following extensions and charts on the Azure Arc enabled Kubernetes cluster:
### Setup RWX Storage Class
1. Install the Azure Container Storage extension
Follow the steps in the [Docs](https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/prepare-linux-edge-volumes)
TL;DR:
```bash
export RG="YOUR_RESOURCE_GROUP_NAME"
export CLUSTER_NAME="YOUR_CLUSTER_NAME"
```
- Install Azure IoT Operations dependencies (for Cert Manager)
```bash
az k8s-extension create --cluster-name "${CLUSTER_NAME}" --name "${CLUSTER_NAME}-certmgr" --resource-group "${RG}" --cluster-type connectedClusters --extension-type microsoft.iotoperations.platform --scope cluster --release-namespace cert-manager
```
-  Install the Azure Container Storage enabled by Azure Arc extension
```bash
az k8s-extension create --resource-group "${RG}" --cluster-name "${CLUSTER_NAME}" --cluster-type connectedClusters --name azure-arc-containerstorage --extension-type microsoft.arc.containerstorage```
- Add the [EdgeStorageConfiguration](https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/install-edge-volumes?tabs=arc#configuration-crd)
1. Create a file named edgeConfig.yaml with the following contents:
```yaml
apiVersion: arccontainerstorage.azure.net/v1
kind: EdgeStorageConfiguration
metadata:
  name: edge-storage-configuration
spec:
  defaultDiskStorageClasses:
    - "default"
```
2. To apply this .yaml file, run:
```bash
kubectl apply -f edgeConfig.yaml
```
3. Validate that the storage class is ready
```bash
kubectl get EdgeStorageConfiguration
kubectl get storageclass
```
`EdgeStorageConfiguration` should have running status.  
The `unbacked-sc` storage class should have been created
### Cluster Networking
1. Make sure that the networking extension (metallb) is installed
2. Make sure that a load balancer is configured 
### Setup Ingress Controller
Install the [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/). 
The example below will install Nginx Ingress Controller in [Load Balancer mode](https://kubernetes.github.io/ingress-nginx/deploy/#azure), and will use NodePort to expose the Ingress Controller.
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.2/deploy/static/provider/cloud/deploy.yaml
```
- Check the ExternalIP assigned to the service (***172.22.86.120***) in the example below)
```bash
kubectl get svc -n ingress-nginx
```
| NAME                                 | TYPE        | CLUSTER-IP       | EXTERNAL-IP | PORT(S)                      | AGE |
|--------------------------------------|-------------|------------------|-------------|------------------------------|-----|
| ingress-nginx-controller             | LoadBalancer    | 10.105.115.144   | 172.22.86.120      | 80:31538/TCP,443:***30617***/TCP   | 10s |
| ingress-nginx-controller-admission   | ClusterIP   | 10.103.106.160   | <none>      | 443/TCP                      | 9s  |

> Note the endpoint URI will be in the format https://<EXTERNAL-IP> (e.g. https://172.22.86.120)
## Video Indexer Setup
### Create a Video Indexer account
### Install the Video Indexer Enabled By Arc Extension
Follow the steps in the [Docs](https://learn.microsoft.com/en-us/azure/azure-video-indexer/arc/azure-video-indexer-enabled-by-arc-quickstart). 
Deployment can be done from the portal or CLI
> During the installation use the `unbacked-sc` storage class and the endpoint from the previous section 
