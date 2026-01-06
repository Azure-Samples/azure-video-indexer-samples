# Video Indexer Arc - AKS Cluster Setup Guide

This guide provides step-by-step instructions for creating an Azure Kubernetes Service (AKS) cluster and deploying the Video Indexer Arc extension.

## Table of Contents

- [Video Indexer Arc - AKS Cluster Setup Guide](#video-indexer-arc---aks-cluster-setup-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Configuration Variables](#configuration-variables)
  - [Step 1: Install CLI Tools](#step-1-install-cli-tools)
  - [Step 2: Create Resource Group](#step-2-create-resource-group)
  - [Step 3: Create AKS Cluster](#step-3-create-aks-cluster)
    - [Add Maintenance Windows (Optional but Recommended)](#add-maintenance-windows-optional-but-recommended)
    - [Get Cluster Credentials](#get-cluster-credentials)
  - [Step 4: Add Node Pools](#step-4-add-node-pools)
    - [General Workload Node Pool (Required)](#general-workload-node-pool-required)
    - [GPU Deepstream Node Pool (Required for Live Pipeline)](#gpu-deepstream-node-pool-required-for-live-pipeline)
    - [GPU Agents Node Pool (Optional - for RAG/Visual Search)](#gpu-agents-node-pool-optional---for-ragvisual-search)
    - [GPU Summarization Node Pool (Optional)](#gpu-summarization-node-pool-optional)
    - [CPU Summarization Node Pool (Optional - Alternative to GPU)](#cpu-summarization-node-pool-optional---alternative-to-gpu)
  - [Step 5: Install NVIDIA GPU Operator](#step-5-install-nvidia-gpu-operator)
  - [Step 6: Configure Ingress Controller](#step-6-configure-ingress-controller)
    - [Create Public IP](#create-public-ip)
    - [Enable App Routing](#enable-app-routing)
    - [Create Nginx Ingress Controller](#create-nginx-ingress-controller)
    - [Verify Ingress Controller](#verify-ingress-controller)
  - [Step 7: Connect to Azure Arc](#step-7-connect-to-azure-arc)
  - [Step 8: Install Cert Manager](#step-8-install-cert-manager)
  - [Step 9: Deploy Video Indexer Arc Extension](#step-9-deploy-video-indexer-arc-extension)
    - [Extension Configuration Variables](#extension-configuration-variables)
    - [Create Extension (Basic Configuration)](#create-extension-basic-configuration)
    - [Create Extension (Full Configuration with Agents and RAG)](#create-extension-full-configuration-with-agents-and-rag)
    - [Verify Extension Installation](#verify-extension-installation)
    - [Update Extension](#update-extension)
    - [Delete Extension](#delete-extension)
    - [Extension Configuration Reference](#extension-configuration-reference)
  - [DNS and SSL Configuration](#dns-and-ssl-configuration)
    - [DNS Options](#dns-options)
    - [SSL/TLS Options](#ssltls-options)
  - [Verification](#verification)
    - [Verify Cluster Status](#verify-cluster-status)
    - [Summary of Created Resources](#summary-of-created-resources)
    - [Node Pool Summary](#node-pool-summary)
  - [Next Steps](#next-steps)
  - [Troubleshooting](#troubleshooting)
    - [Extension Not Installing](#extension-not-installing)
    - [GPU Nodes Not Scaling](#gpu-nodes-not-scaling)
    - [Ingress Not Getting IP](#ingress-not-getting-ip)
    - [Arc Connection Issues](#arc-connection-issues)
  - [Clean Up](#clean-up)

---

## Prerequisites

- Azure CLI installed and logged in
- kubectl installed
- Helm 3.x installed
- Sufficient Azure quota for GPU VMs in your region
- Azure subscription with required permissions

---

## Configuration Variables

Before starting, set these environment variables in your terminal. Replace the placeholder values with your actual values:

```bash
# REQUIRED: Your Azure configuration
export SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
export REGION="<YOUR_AZURE_REGION>"           # e.g., eastus, westus2, westeurope
export RESOURCES_PREFIX="<YOUR_PREFIX>"       # e.g., mycompany-vi-arc

# Derived names (you can customize these)
export RG="${RESOURCES_PREFIX}-rg"
export AKS="${RESOURCES_PREFIX}-aks"
export CONNECTED_CLUSTER="${RESOURCES_PREFIX}-connected-aks"
export NODEPOOL_RG="${AKS}-agentpool-rg"
export KUBECTL_CONTEXT="${RESOURCES_PREFIX}"
export TAGS="createdBy=${RESOURCES_PREFIX} purpose=vi-arc-deployment"

# VM Sizes (recommended defaults)
export NODE_VM_SIZE="Standard_D4a_v4"           # System nodes: 4 vcpus, 16 GB RAM
export WORKER_VM_SIZE="Standard_D32a_v4"        # Workload nodes: 32 vcpus, 128 GB RAM
export SUMMARIZATION_CPU_VM="Standard_F32s_v2"  # CPU summarization: 32 vcpus, 64 GB RAM
export GPU_VM_SIZE="Standard_NC40ads_H100_v5"   # GPU nodes: 1 H100 GPU, 40 vcpus

# Feature flags (set to "true" to enable)
export ENABLE_AGENTS="false"           # RAG, visual search features
export ENABLE_SUMMARIZATION_GPU="false" # GPU-based summarization
export ENABLE_SUMMARIZATION_CPU="false" # CPU-based summarization
```

---

## Step 1: Install CLI Tools

Install required Azure CLI extensions and register providers:

```bash
# Install/update Azure CLI extensions
az extension add --name connectedk8s --upgrade --yes
az extension add --name k8s-extension --upgrade --yes
az extension add --name aks-preview --upgrade --yes

# Register required providers
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation
```

---

## Step 2: Create Resource Group

```bash
# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
az group create --name $RG --location $REGION --tags $TAGS
```

---

## Step 3: Create AKS Cluster

Get the latest AKS version and create the cluster:

```bash
# Get latest AKS version
AKS_VERSION=$(az aks get-versions --location $REGION \
    --query "values[].patchVersions.keys(@)[][] | sort(@) | [-1]" | tr -d '"')
echo "AKS Version: $AKS_VERSION"

# Create AKS cluster
az aks create -n $AKS -g $RG \
    --enable-managed-identity \
    --enable-workload-identity \
    --enable-addons azure-keyvault-secrets-provider \
    --kubernetes-version ${AKS_VERSION} \
    --enable-oidc-issuer \
    --nodepool-name system \
    --os-sku AzureLinux \
    --node-count 2 \
    --tier standard \
    --generate-ssh-keys \
    --network-plugin kubenet \
    --tags $TAGS \
    --node-resource-group $NODEPOOL_RG \
    --node-vm-size $NODE_VM_SIZE \
    --enable-image-cleaner --image-cleaner-interval-hours 24 \
    --node-os-upgrade-channel NodeImage --auto-upgrade-channel node-image
```

### Add Maintenance Windows (Optional but Recommended)

```bash
# Auto-upgrade maintenance window
az aks maintenanceconfiguration add --resource-group $RG --cluster-name $AKS \
    --name aksManagedAutoUpgradeSchedule --schedule-type Weekly \
    --day-of-week Friday --interval-weeks 3 --duration 8 \
    --utc-offset +00:00 --start-time 00:00

# Node OS upgrade maintenance window
az aks maintenanceconfiguration add --resource-group $RG --cluster-name $AKS \
    --name aksManagedNodeOSUpgradeSchedule --schedule-type Weekly \
    --day-of-week Friday --interval-weeks 1 --duration 8 \
    --utc-offset +00:00 --start-time 00:00
```

### Get Cluster Credentials

```bash
az aks get-credentials --resource-group $RG --name $AKS --admin \
    --overwrite-existing --context ${KUBECTL_CONTEXT}

# Rename context to remove -admin suffix
kubectl config rename-context ${KUBECTL_CONTEXT}-admin ${KUBECTL_CONTEXT} 2>/dev/null || true

# Verify connectivity
kubectl get nodes --context ${KUBECTL_CONTEXT}
```

---

## Step 4: Add Node Pools

### General Workload Node Pool (Required)

```bash
az aks nodepool add -g $RG --cluster-name $AKS -n workload \
    --os-sku AzureLinux \
    --mode User \
    --node-vm-size $WORKER_VM_SIZE \
    --node-osdisk-size 100 \
    --node-count 0 \
    --max-count 10 \
    --min-count 0 \
    --tags $TAGS \
    --enable-cluster-autoscaler \
    --max-pods 110
```

### GPU Deepstream Node Pool (Required for Live Pipeline)

```bash
az aks nodepool add -g $RG --cluster-name $AKS -n gpudeepstrm \
    --os-sku Ubuntu \
    --mode User \
    --node-vm-size $GPU_VM_SIZE \
    --node-osdisk-size 200 \
    --node-count 0 \
    --max-count 1 \
    --min-count 0 \
    --tags $TAGS \
    --enable-cluster-autoscaler \
    --node-taints nvidia.com/gpu=true:NoSchedule \
    --labels workload=deepstream \
    --max-pods 110
```

### GPU Agents Node Pool (Optional - for RAG/Visual Search)

Only add this if you need AI agents features (RAG, visual search, etc.):

```bash
# Only run if ENABLE_AGENTS="true"
az aks nodepool add -g $RG --cluster-name $AKS -n gpuagents \
    --os-sku Ubuntu \
    --mode User \
    --node-vm-size $GPU_VM_SIZE \
    --node-osdisk-size 200 \
    --node-count 0 \
    --max-count 2 \
    --min-count 0 \
    --tags $TAGS \
    --enable-cluster-autoscaler \
    --node-taints nvidia.com/gpu=true:NoSchedule \
    --labels workload=agents \
    --max-pods 110
```

### GPU Summarization Node Pool (Optional)

Only add this if you need GPU-based summarization:

```bash
# Only run if ENABLE_SUMMARIZATION_GPU="true"
az aks nodepool add -g $RG --cluster-name $AKS -n gpusumm \
    --os-sku Ubuntu \
    --mode User \
    --node-vm-size $GPU_VM_SIZE \
    --node-osdisk-size 200 \
    --node-count 0 \
    --max-count 1 \
    --min-count 0 \
    --tags $TAGS \
    --enable-cluster-autoscaler \
    --node-taints nvidia.com/gpu=true:NoSchedule \
    --labels workload=summarization \
    --max-pods 110
```

### CPU Summarization Node Pool (Optional - Alternative to GPU)

Only add this if you want CPU-based summarization (alternative to GPU):

```bash
# Only run if ENABLE_SUMMARIZATION_CPU="true"
az aks nodepool add -g $RG --cluster-name $AKS -n workloadf32 \
    --os-sku AzureLinux \
    --mode User \
    --node-vm-size $SUMMARIZATION_CPU_VM \
    --node-osdisk-size 100 \
    --node-count 0 \
    --max-count 5 \
    --min-count 0 \
    --tags $TAGS \
    --enable-cluster-autoscaler \
    --labels workload=summarization \
    --max-pods 110
```

---

## Step 5: Install NVIDIA GPU Operator

Install the NVIDIA GPU operator for GPU workloads:

```bash
# Add NVIDIA Helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install GPU operator
helm upgrade -i gpu-operator --wait -n gpu-operator --create-namespace \
    --version v25.3.2 \
    nvidia/gpu-operator --kube-context ${KUBECTL_CONTEXT}
```

---

## Step 6: Configure Ingress Controller

### Create Public IP

```bash
# Create static public IP
az network public-ip create -g $NODEPOOL_RG -n ${RESOURCES_PREFIX}-inbound-ip \
    --sku Standard --allocation-method static

# Get the IP address
PUBLIC_IP=$(az network public-ip show -g $NODEPOOL_RG -n ${RESOURCES_PREFIX}-inbound-ip \
    --query ipAddress -o tsv)
echo "Public IP: ${PUBLIC_IP}"

# Configure DNS label (creates <prefix>.<region>.cloudapp.azure.com)
az network public-ip update -g $NODEPOOL_RG -n ${RESOURCES_PREFIX}-inbound-ip \
    --dns-name ${RESOURCES_PREFIX}

FQDN="${RESOURCES_PREFIX}.${REGION}.cloudapp.azure.com"
echo "FQDN: ${FQDN}"
```

### Enable App Routing

**Option A: Without SSL (HTTP only)**

```bash
az aks approuting enable -g $RG -n $AKS
```

**Option B: With SSL from Azure Key Vault**

```bash
# Set your Key Vault name
export KEY_VAULT_NAME="<YOUR_KEYVAULT_NAME>"

# Get Key Vault ID
KEYVAULT_ID=$(az keyvault show --name $KEY_VAULT_NAME --query "id" --output tsv)

# Enable app routing with Key Vault
az aks approuting enable -g $RG -n $AKS --enable-kv --attach-kv $KEYVAULT_ID
```

### Create Nginx Ingress Controller

**Option A: Without SSL**

```bash
cat <<EOF | kubectl apply -f - --context ${KUBECTL_CONTEXT}
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: nginx
spec:
  ingressClassName: nginx
  controllerNamePrefix: nginx
  loadBalancerAnnotations: 
    service.beta.kubernetes.io/azure-pip-name: ${RESOURCES_PREFIX}-inbound-ip
    service.beta.kubernetes.io/azure-load-balancer-resource-group: ${NODEPOOL_RG}
EOF
```

**Option B: With SSL Certificate from Key Vault**

```bash
# Set your certificate URI
export SSL_CERT_URI="https://<YOUR_KEYVAULT>.vault.azure.net/certificates/<CERT_NAME>"

cat <<EOF | kubectl apply -f - --context ${KUBECTL_CONTEXT}
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: nginx
spec:
  ingressClassName: nginx
  controllerNamePrefix: nginx
  loadBalancerAnnotations: 
    service.beta.kubernetes.io/azure-pip-name: ${RESOURCES_PREFIX}-inbound-ip
    service.beta.kubernetes.io/azure-load-balancer-resource-group: ${NODEPOOL_RG}
  defaultSSLCertificate:
    keyVaultURI: "${SSL_CERT_URI}"
EOF
```

### Verify Ingress Controller

```bash
# Wait for nginx to get external IP
kubectl get svc nginx -n app-routing-system --context ${KUBECTL_CONTEXT} -w
```

---

## Step 7: Connect to Azure Arc

Connect your AKS cluster to Azure Arc:

```bash
az connectedk8s connect --name ${CONNECTED_CLUSTER} --resource-group $RG --yes

# Verify connection
az connectedk8s show --name ${CONNECTED_CLUSTER} --resource-group $RG \
    --query "connectivityStatus" -o tsv
```

---

## Step 8: Install Cert Manager

Install the cert-manager extension required for Video Indexer Arc:

```bash
CM_EXT_NAME="${AKS}-certmgr"

az k8s-extension create \
    --cluster-name "${CONNECTED_CLUSTER}" \
    --name "${CM_EXT_NAME}" \
    --resource-group "${RG}" \
    --cluster-type connectedClusters \
    --extension-type microsoft.iotoperations.platform \
    --scope cluster \
    --release-namespace cert-manager

# Wait for extension to be ready
az k8s-extension show \
    --cluster-name "${CONNECTED_CLUSTER}" \
    --resource-group "${RG}" \
    --cluster-type connectedClusters \
    --name "${CM_EXT_NAME}" \
    --query "provisioningState" -o tsv
```

---

## Step 9: Deploy Video Indexer Arc Extension

This step deploys the Video Indexer Arc extension to your cluster.

### Extension Configuration Variables

Set the following variables for your Video Indexer Arc extension:

```bash
# REQUIRED: Video Indexer Extension Configuration
export VI_EXTENSION_NAME="video-indexer"
export VI_EXTENSION_VERSION="<YOUR_EXTENSION_VERSION>"  # e.g., "1.2.53" - Get the latest stable version

# REQUIRED: Video Indexer Account Information
export VI_ACCOUNT_ID="<YOUR_VI_ACCOUNT_ID>"              # Your Video Indexer account ID (GUID)
export VI_ACCOUNT_RESOURCE_ID="<YOUR_VI_ACCOUNT_RESOURCE_ID>"  # Full ARM resource ID of your VI account
# Format: /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.VideoIndexer/accounts/<account-name>

# REQUIRED: Endpoint URI (your cluster's public endpoint)
export VI_ENDPOINT_URI="https://${FQDN}"  # Or your custom domain if configured

# Feature Flags (set to "true" to enable)
export VI_LIVE_VIDEO_ENABLED="true"       # Enable live video stream processing
export VI_MEDIA_UPLOADS_ENABLED="true"    # Enable media file uploads
export VI_LIVE_SUMMARIZATION_ENABLED="true"  # Enable live summarization
export VI_GPU_SUMMARIZATION="false"       # Use GPU for summarization

# Agents Configuration (Optional - requires gpuagents node pool)
export VI_AGENTS_ENABLED="false"          # Enable AI agents
export VI_AGENTS_MODE="basic"             # Options: "basic" or "advanced"

# RAG Configuration (Optional - requires agents enabled)
export VI_RAG_ENABLED="false"
export VI_RAG_ENDPOINT=""                 # RAG service endpoint
export VI_RAG_APPLICATION_ID=""           # RAG application ID
export VI_RAG_MANAGED_IDENTITY_CLIENT_ID="" # Managed identity client ID for RAG
export VI_RAG_TENANT_ID=""                # Azure tenant ID

# Node Selectors (Optional - match your node pool labels)
export VI_DEEPSTREAM_NODE_SELECTOR="deepstream"     # Node selector for deepstream workloads
export VI_SUMMARIZATION_NODE_SELECTOR="summarization" # Node selector for summarization
export VI_INFERENCE_NODE_SELECTOR="agents"          # Node selector for inference/agents

# GPU Tolerations
export VI_GPU_TOLERATIONS_KEY="nvidia.com/gpu"
```

### Create Extension (Basic Configuration)

For a basic deployment with live video and media uploads:

```bash
az k8s-extension create \
    --name ${VI_EXTENSION_NAME} \
    --extension-type "Microsoft.videoIndexer" \
    --scope cluster \
    --release-namespace "video-indexer" \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --version ${VI_EXTENSION_VERSION} \
    --release-train "stable" \
    --auto-upgrade-minor-version "false" \
    --config "videoIndexer.accountId=${VI_ACCOUNT_ID}" \
    --config "videoIndexer.accountResourceId=${VI_ACCOUNT_RESOURCE_ID}" \
    --config "videoIndexer.endpointUri=${VI_ENDPOINT_URI}" \
    --config "videoIndexer.mediaUploadsEnabled=${VI_MEDIA_UPLOADS_ENABLED}" \
    --config "videoIndexer.liveVideoStreamEnabled=${VI_LIVE_VIDEO_ENABLED}" \
    --config "ViAi.LiveSummarization.enabled=${VI_LIVE_SUMMARIZATION_ENABLED}" \
    --config "ViAi.gpu.enabled=${VI_GPU_SUMMARIZATION}" \
    --config "ViAi.gpu.tolerations.key=${VI_GPU_TOLERATIONS_KEY}" \
    --config "ViAi.deepstream.nodeSelector.workload=${VI_DEEPSTREAM_NODE_SELECTOR}" \
    --config "storage.storageClass=azurefile-csi" \
    --config "storage.accessMode=ReadWriteMany"
```

### Create Extension (Full Configuration with Agents and RAG)

For a full deployment with agents and RAG features:

```bash
az k8s-extension create \
    --name ${VI_EXTENSION_NAME} \
    --extension-type "Microsoft.videoIndexer" \
    --scope cluster \
    --release-namespace "video-indexer" \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --version ${VI_EXTENSION_VERSION} \
    --release-train "stable" \
    --auto-upgrade-minor-version "false" \
    --config "videoIndexer.accountId=${VI_ACCOUNT_ID}" \
    --config "videoIndexer.accountResourceId=${VI_ACCOUNT_RESOURCE_ID}" \
    --config "videoIndexer.endpointUri=${VI_ENDPOINT_URI}" \
    --config "videoIndexer.mediaUploadsEnabled=${VI_MEDIA_UPLOADS_ENABLED}" \
    --config "videoIndexer.liveVideoStreamEnabled=${VI_LIVE_VIDEO_ENABLED}" \
    --config "videoIndexer.rag.enabled=${VI_RAG_ENABLED}" \
    --config "videoIndexer.rag.endpoint=${VI_RAG_ENDPOINT}" \
    --config "videoIndexer.rag.applicationId=${VI_RAG_APPLICATION_ID}" \
    --config "videoIndexer.rag.managedIdentityClientId=${VI_RAG_MANAGED_IDENTITY_CLIENT_ID}" \
    --config "videoIndexer.rag.tenantId=${VI_RAG_TENANT_ID}" \
    --config "videoIndexer.agents.enabled=${VI_AGENTS_ENABLED}" \
    --config "videoIndexer.agents.mode=${VI_AGENTS_MODE}" \
    --config "ViAi.LiveSummarization.enabled=${VI_LIVE_SUMMARIZATION_ENABLED}" \
    --config "ViAi.gpu.enabled=${VI_GPU_SUMMARIZATION}" \
    --config "ViAi.gpu.tolerations.key=${VI_GPU_TOLERATIONS_KEY}" \
    --config "ViAi.deepstream.nodeSelector.workload=${VI_DEEPSTREAM_NODE_SELECTOR}" \
    --config "ViAi.summarization.nodeSelector.workload=${VI_SUMMARIZATION_NODE_SELECTOR}" \
    --config "ViAi.inference.nodeSelector.workload=${VI_INFERENCE_NODE_SELECTOR}" \
    --config "storage.storageClass=azurefile-csi" \
    --config "storage.accessMode=ReadWriteMany"
```

### Verify Extension Installation

```bash
# Check extension status
az k8s-extension show \
    --name ${VI_EXTENSION_NAME} \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --query "{name:name, provisioningState:provisioningState, version:version}"

# Check pods in video-indexer namespace
kubectl get pods -n video-indexer --context ${KUBECTL_CONTEXT}
```

### Update Extension

To update an existing extension with new configuration:

```bash
az k8s-extension update \
    --name ${VI_EXTENSION_NAME} \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --version ${VI_EXTENSION_VERSION} \
    --release-train "stable" \
    --auto-upgrade-minor-version "false" \
    --config "videoIndexer.accountId=${VI_ACCOUNT_ID}" \
    --config "videoIndexer.accountResourceId=${VI_ACCOUNT_RESOURCE_ID}" \
    --config "videoIndexer.endpointUri=${VI_ENDPOINT_URI}" \
    --config "videoIndexer.mediaUploadsEnabled=${VI_MEDIA_UPLOADS_ENABLED}" \
    --config "videoIndexer.liveVideoStreamEnabled=${VI_LIVE_VIDEO_ENABLED}" \
    --config "ViAi.LiveSummarization.enabled=${VI_LIVE_SUMMARIZATION_ENABLED}" \
    --config "ViAi.gpu.enabled=${VI_GPU_SUMMARIZATION}" \
    --config "ViAi.gpu.tolerations.key=${VI_GPU_TOLERATIONS_KEY}" \
    --config "storage.storageClass=azurefile-csi" \
    --yes
```

### Delete Extension

To remove the extension:

```bash
az k8s-extension delete \
    --name ${VI_EXTENSION_NAME} \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --yes
```

### Extension Configuration Reference

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `videoIndexer.accountId` | Video Indexer account GUID | Yes | - |
| `videoIndexer.accountResourceId` | Full ARM resource ID | Yes | - |
| `videoIndexer.endpointUri` | Public endpoint URI | Yes | - |
| `videoIndexer.mediaUploadsEnabled` | Enable media uploads | No | true |
| `videoIndexer.liveVideoStreamEnabled` | Enable live video | No | false |
| `ViAi.LiveSummarization.enabled` | Enable live summarization | No | true |
| `ViAi.gpu.enabled` | Use GPU for summarization | No | false |
| `ViAi.gpu.tolerations.key` | GPU node taint key | No | nvidia.com/gpu |
| `videoIndexer.agents.enabled` | Enable AI agents | No | false |
| `videoIndexer.agents.mode` | Agents mode (basic/advanced) | No | basic |
| `videoIndexer.rag.enabled` | Enable RAG features | No | false |
| `videoIndexer.rag.endpoint` | RAG service endpoint | If RAG enabled | - |
| `videoIndexer.rag.applicationId` | RAG application ID | If RAG enabled | - |
| `videoIndexer.rag.managedIdentityClientId` | Managed identity for RAG | If RAG enabled | - |
| `videoIndexer.rag.tenantId` | Azure tenant ID | If RAG enabled | - |
| `storage.storageClass` | Kubernetes storage class | No | azurefile-csi |
| `storage.accessMode` | Storage access mode | No | ReadWriteMany |

---

## DNS and SSL Configuration

### DNS Options

You have two options for DNS:

1. **Azure Public DNS Label** (Automatic): Use the Azure-provided FQDN:
   ```
   <your-prefix>.<region>.cloudapp.azure.com
   ```

2. **Custom Domain**: Configure your own DNS to point to the public IP:
   - Create an A record pointing to: `${PUBLIC_IP}`
   - Or create a CNAME pointing to the Azure FQDN

### SSL/TLS Options

> **Note**: SSL certificate setup requires you to have a certificate in Azure Key Vault. The process of obtaining and registering a certificate varies by organization and certificate authority.

**Option 1: No SSL (HTTP only)**
- Use the nginx ingress controller configuration without `defaultSSLCertificate`
- Suitable for development/testing environments

**Option 2: SSL with Azure Key Vault**
1. Obtain an SSL certificate for your domain
2. Import the certificate into Azure Key Vault
3. Use the Key Vault URI in the nginx ingress controller configuration
4. Ensure the AKS managed identity has access to the Key Vault

---

## Verification

### Verify Cluster Status

```bash
# Check all nodes
kubectl get nodes --context ${KUBECTL_CONTEXT}

# Check GPU operator
kubectl get pods -n gpu-operator --context ${KUBECTL_CONTEXT}

# Check ingress controller
kubectl get svc nginx -n app-routing-system --context ${KUBECTL_CONTEXT}

# Check Arc connection
az connectedk8s show --name ${CONNECTED_CLUSTER} --resource-group $RG \
    --query "{name:name, status:connectivityStatus}" -o table
```

### Summary of Created Resources

| Resource | Name | Description |
|----------|------|-------------|
| Resource Group | `${RESOURCES_PREFIX}-rg` | Contains all resources |
| AKS Cluster | `${RESOURCES_PREFIX}-aks` | Kubernetes cluster |
| Node Pool RG | `${RESOURCES_PREFIX}-aks-agentpool-rg` | Node pool resources |
| Public IP | `${RESOURCES_PREFIX}-inbound-ip` | Ingress IP |
| Arc Connected Cluster | `${RESOURCES_PREFIX}-connected-aks` | Arc connection |

### Node Pool Summary

| Pool Name | Purpose | VM Size | Scale Range |
|-----------|---------|---------|-------------|
| system | Kubernetes system | Standard_D4a_v4 | 2 (fixed) |
| workload | General VI workloads | Standard_D32a_v4 | 0-10 (auto) |
| gpudeepstrm | Live pipeline/deepstream | Standard_NC40ads_H100_v5 | 0-1 (auto) |
| gpuagents | AI agents (optional) | Standard_NC40ads_H100_v5 | 0-2 (auto) |
| gpusumm | GPU summarization (optional) | Standard_NC40ads_H100_v5 | 0-1 (auto) |
| workloadf32 | CPU summarization (optional) | Standard_F32s_v2 | 0-5 (auto) |

---

## Next Steps

After completing the cluster setup and extension deployment:

1. Access the Video Indexer portal at your configured endpoint URI
2. Test live video stream processing with a camera source
3. Upload test media files to verify indexing
4. Configure alerts and monitoring as needed

For additional documentation and API reference, visit the Video Indexer documentation.

---

## Troubleshooting

### Extension Not Installing

```bash
# Check extension provisioning state
az k8s-extension show \
    --name ${VI_EXTENSION_NAME} \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --query "provisioningState"

# Check extension error message
az k8s-extension show \
    --name ${VI_EXTENSION_NAME} \
    --cluster-name ${CONNECTED_CLUSTER} \
    --resource-group ${RG} \
    --cluster-type "connectedClusters" \
    --query "statuses"

# Check pods in video-indexer namespace
kubectl get pods -n video-indexer --context ${KUBECTL_CONTEXT}
kubectl describe pods -n video-indexer --context ${KUBECTL_CONTEXT}
```

### GPU Nodes Not Scaling

```bash
# Check GPU operator status
kubectl get pods -n gpu-operator --context ${KUBECTL_CONTEXT}

# Check node pool status
az aks nodepool show -g $RG --cluster-name $AKS -n gpudeepstrm --query "powerState.code"
```

### Ingress Not Getting IP

```bash
# Check nginx controller status
kubectl describe NginxIngressController nginx -n app-routing-system --context ${KUBECTL_CONTEXT}

# Check service status
kubectl describe svc nginx -n app-routing-system --context ${KUBECTL_CONTEXT}
```

### Arc Connection Issues

```bash
# Check Arc agent status
kubectl get pods -n azure-arc --context ${KUBECTL_CONTEXT}

# Reconnect if needed
az connectedk8s connect --name ${CONNECTED_CLUSTER} --resource-group $RG --yes
```

---

## Clean Up

To delete all resources:

```bash
# Delete Arc connection first
az connectedk8s delete --name ${CONNECTED_CLUSTER} --resource-group $RG --yes

# Delete resource group (this deletes everything)
az group delete --name $RG --yes --no-wait
```
