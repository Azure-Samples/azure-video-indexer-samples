# Video Indexer Arc - AKS Cluster Setup Guide

This guide provides step-by-step instructions for creating an Azure Kubernetes Service (AKS) cluster and deploying the Video Indexer Arc extension.

## Table of Contents

- [Video Indexer Arc - AKS Cluster Setup Guide](#video-indexer-arc---aks-cluster-setup-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
    - [Check GPU Quota](#check-gpu-quota)
    - [How to Request GPU Quota](#how-to-request-gpu-quota)
    - [Get Your Subscription ID](#get-your-subscription-id)
    - [Get Your Video Indexer Account Details](#get-your-video-indexer-account-details)
  - [Configuration Variables](#configuration-variables)
    - [AKS Cluster Variables](#aks-cluster-variables)
    - [Video Indexer Arc Extension Variables](#video-indexer-arc-extension-variables)
  - [Step 1: Install CLI Tools](#step-1-install-cli-tools)
  - [Step 2: Create Resource Group](#step-2-create-resource-group)
  - [Step 3: Create AKS Cluster ⏱️ ~5-10 min](#step-3-create-aks-cluster-️-5-10-min)
    - [Add Maintenance Windows (Optional but Recommended)](#add-maintenance-windows-optional-but-recommended)
    - [Get Cluster Credentials](#get-cluster-credentials)
  - [Step 4: Add Node Pools](#step-4-add-node-pools)
    - [General Workload Node Pool (Required)](#general-workload-node-pool-required)
    - [GPU Deepstream Node Pool (Required for Live Pipeline)](#gpu-deepstream-node-pool-required-for-live-pipeline)
    - [GPU Summarization Node Pool (Optional)](#gpu-summarization-node-pool-optional)
    - [CPU Summarization Node Pool (Optional - Alternative to GPU)](#cpu-summarization-node-pool-optional---alternative-to-gpu)
  - [Step 5: Install NVIDIA GPU Operator ⏱️ ~3-5 min](#step-5-install-nvidia-gpu-operator-️-3-5-min)
  - [Step 6: Configure Ingress Controller](#step-6-configure-ingress-controller)
    - [Create Public IP](#create-public-ip)
    - [Enable App Routing](#enable-app-routing)
    - [Create Nginx Ingress Controller](#create-nginx-ingress-controller)
    - [Verify Ingress Controller](#verify-ingress-controller)
  - [Step 7: Connect to Azure Arc ⏱️ ~3-5 min](#step-7-connect-to-azure-arc-️-3-5-min)
  - [Step 8: Install Cert Manager](#step-8-install-cert-manager)
  - [Step 9: Deploy Video Indexer Arc Extension ⏱️ ~5-15 min](#step-9-deploy-video-indexer-arc-extension-️-5-15-min)
    - [Create Extension (Basic Configuration)](#create-extension-basic-configuration)
    - [Create Extension (Advanced Configuration with GPU Summarization)](#create-extension-advanced-configuration-with-gpu-summarization)
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
- Bash-compatible shell (WSL, Git Bash, or Azure Cloud Shell)
- Sufficient Azure quota for GPU VMs in your region (see quota check below)
- Azure subscription with required permissions

### Check GPU Quota

Before starting, verify you have sufficient GPU quota in your target region. Video Indexer Arc supports various GPU types:

| GPU Type | VM Size Example | Use Case |
|----------|-----------------|----------|
| H100 | Standard_NC40ads_H100_v5 | Best performance |
| A100 | Standard_NC24ads_A100_v4 | High performance |
| A10 | Standard_NV36ads_A10_v5 | Cost-effective option |

Check your quota for each GPU type you plan to use:

```bash
# Set your target region first
export REGION="<YOUR_AZURE_REGION>"

# Check H100 quota
az vm list-usage --location $REGION -o table | grep -i H100
```

**Example Output:**
```
Name                                      CurrentValue    Limit
----------------------------------------  --------------  -------
Standard NCadsH100v5 Family vCPUs         0               40
```

```bash
# Check A100 quota
az vm list-usage --location $REGION -o table | grep -i A100
```

**Example Output:**
```
Name                                      CurrentValue    Limit
----------------------------------------  --------------  -------
Standard NCADS_A100_v4 Family vCPUs       0               24
```

```bash
# Check A10 quota
az vm list-usage --location $REGION -o table | grep -i A10
```

**Example Output:**
```
Name                                      CurrentValue    Limit
----------------------------------------  --------------  -------
Standard NVadsA10 v5 Family vCPUs         0               36
```

> ⚠️ **Important**: If your quota shows 0 available (Limit = 0), you'll need to request a quota increase before proceeding. This can take several days.

### How to Request GPU Quota

If you don't have sufficient GPU quota in your region, follow these steps to request an increase:

1. **Navigate to Azure Portal**: Go to [https://portal.azure.com](https://portal.azure.com)

2. **Open Quotas**: Search for "Quotas" in the search bar and select "Quotas"

3. **Select Compute**: Click on "Compute" to view VM quotas

4. **Filter by Region and VM Family**:
   - Filter by your target region (e.g., `eastus`, `westeurope`)
   - Search for the GPU VM family you need (e.g., "NCadsH100", "NCADS_A100", "NVadsA10")

5. **Request Increase**:
   - Select the quota you want to increase
   - Click "Request quota increase" or the pencil icon
   - Enter your desired new limit (e.g., 40 vCPUs for 1 H100 VM)
   - Provide a business justification

6. **Alternative Regions**: If quota is unavailable in your preferred region, try these alternatives:
   - `eastus2`, `westus2`, `westeurope`, `northeurope`, `southeastasia`
   - Check available regions: `az vm list-skus --size Standard_NC --all --output table`

7. **Check Request Status**:
   ```bash
   # List your quota requests
   az support tickets list --output table
   ```

> 💡 **Tip**: GPU quota requests typically take 1-5 business days. For urgent needs, contact Azure Support directly.

### Get Your Subscription ID

```bash
# List all subscriptions and find your subscription ID
az account list --output table
```

**Example Output:**
```
Name                    CloudName    SubscriptionId                        State    IsDefault
----------------------  -----------  ------------------------------------  -------  -----------
My-Production-Sub       AzureCloud   12345678-1234-1234-1234-123456789abc  Enabled  True
My-Development-Sub      AzureCloud   abcdef12-abcd-abcd-abcd-abcdef123456  Enabled  False
```

```bash
# Get the current subscription ID
az account show --query id -o tsv
```

**Example Output:**
```
12345678-1234-1234-1234-123456789abc
```

### Get Your Video Indexer Account Details

To deploy the Video Indexer Arc extension, you need the following information from your Video Indexer account:

```bash
# List all Video Indexer accounts in your subscription
az rest --method get \
    --uri "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.VideoIndexer/accounts?api-version=2024-01-01" \
    --query "value[].{name:name, resourceGroup:resourceGroup, accountId:properties.accountId, location:location, resourceId:id}" \
    -o table
```

**Example Output:**
```
Name              ResourceGroup     AccountId                             Location    ResourceId
----------------  ----------------  ------------------------------------  ----------  ------------------------------------------------------------------------------------------------
my-vi-account     my-vi-rg          a1b2c3d4-e5f6-7890-abcd-ef1234567890  eastus      /subscriptions/12345678-.../resourceGroups/my-vi-rg/providers/Microsoft.VideoIndexer/accounts/my-vi-account
```

Or use this command to get detailed information for a specific account:

```bash
# Set your Video Indexer account details
export VI_RESOURCE_GROUP="<YOUR_VI_RESOURCE_GROUP>"
export VI_ACCOUNT_NAME="<YOUR_VI_ACCOUNT_NAME>"

# Get account details
az rest --method get \
    --uri "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${VI_RESOURCE_GROUP}/providers/Microsoft.VideoIndexer/accounts/${VI_ACCOUNT_NAME}?api-version=2024-01-01" \
    --query "{accountId:properties.accountId, accountName:name, resourceId:id, location:location}"
```

**Example Output:**
```json
{
  "accountId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "accountName": "my-vi-account",
  "resourceId": "/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/my-vi-rg/providers/Microsoft.VideoIndexer/accounts/my-vi-account",
  "location": "eastus"
}
```

Use these values in your extension configuration:
- `accountId` → `VI_ACCOUNT_ID`
- `resourceId` → `VI_ACCOUNT_RESOURCE_ID`

---

## Configuration Variables

Before starting, set these environment variables in your terminal. The variables are organized into two sections:
1. **AKS Cluster Variables** - Required for creating the AKS cluster infrastructure
2. **Video Indexer Arc Extension Variables** - Required for installing the VI extension (can be done on an existing cluster)

### AKS Cluster Variables

Set these variables if you need to create a new AKS cluster:

```bash
#===========================================================================================================#
# AKS CLUSTER CONFIGURATION
# Use these variables to create a new AKS cluster for Video Indexer Arc
#===========================================================================================================#

# REQUIRED: Your Azure configuration
export SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
export REGION="<YOUR_AZURE_REGION>"           # e.g., eastus, westus2, westeurope

# REQUIRED: Resource naming prefix (used for all resources)
# NOTE: A random suffix is added to DNS names to avoid collisions
export RESOURCES_PREFIX="<YOUR_PREFIX>"       # e.g., mycompany-vi-arc
export RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)  # Random 3-digit number to avoid DNS collisions

# Derived names (you can customize these)
export RG="${RESOURCES_PREFIX}-rg"
export AKS="${RESOURCES_PREFIX}-aks"
export CONNECTED_CLUSTER="${RESOURCES_PREFIX}-connected-aks"
export NODEPOOL_RG="${AKS}-agentpool-rg"
export KUBECTL_CONTEXT="${RESOURCES_PREFIX}"
export TAGS="createdBy=${RESOURCES_PREFIX} purpose=vi-arc-deployment"

# DNS name with random suffix to avoid collisions (Azure public DNS requires unique names per region)
export DNS_LABEL="${RESOURCES_PREFIX}${RANDOM_SUFFIX}"

# VM Sizes (recommended defaults)
export NODE_VM_SIZE="Standard_D4a_v4"           # System nodes: 4 vcpus, 16 GB RAM
export WORKER_VM_SIZE="Standard_D32a_v4"        # Workload nodes: 32 vcpus, 128 GB RAM
export SUMMARIZATION_CPU_VM="Standard_F32s_v2"  # CPU summarization: 32 vcpus, 64 GB RAM
export GPU_VM_SIZE="Standard_NC40ads_H100_v5"   # GPU nodes: 1 H100 GPU, 40 vcpus

# Feature flags (set to "true" to enable)
export ENABLE_SUMMARIZATION_GPU="false" # GPU-based summarization
export ENABLE_SUMMARIZATION_CPU="false" # CPU-based summarization
```

### Video Indexer Arc Extension Variables

Set these variables to install the Video Indexer Arc extension. These can be used independently if you already have an Arc-connected Kubernetes cluster:

```bash
#===========================================================================================================#
# VIDEO INDEXER ARC EXTENSION CONFIGURATION
# Use these variables to install the VI extension on any Arc-connected Kubernetes cluster
#===========================================================================================================#

# REQUIRED: Video Indexer Extension Configuration
export VI_EXTENSION_NAME="video-indexer"
export VI_EXTENSION_VERSION="<YOUR_EXTENSION_VERSION>"  # e.g., "1.2.53" - Get the latest version

# NOTE: Currently using preview release train. Change to "stable" when stable versions are released.
export VI_RELEASE_TRAIN="preview"  # Options: "preview" or "stable" (use "stable" for production when available)

# REQUIRED: Video Indexer Account Information (get these from the "Get Your Video Indexer Account Details" section above)
export VI_ACCOUNT_ID="<YOUR_VI_ACCOUNT_ID>"              # Your Video Indexer account ID (GUID)
export VI_ACCOUNT_RESOURCE_ID="<YOUR_VI_ACCOUNT_RESOURCE_ID>"  # Full ARM resource ID of your VI account
# Format: /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.VideoIndexer/accounts/<account-name>

# REQUIRED: Endpoint URI (your cluster's public endpoint)
# NOTE: Uses DNS_LABEL with random suffix to avoid collisions
export VI_ENDPOINT_URI="https://${DNS_LABEL}.${REGION}.cloudapp.azure.com"

# Feature Flags (set to "true" to enable)
export VI_LIVE_VIDEO_ENABLED="true"         # Enable live video stream processing
export VI_MEDIA_UPLOADS_ENABLED="true"      # Enable media file uploads
export VI_LIVE_SUMMARIZATION_ENABLED="false" # Enable live summarization (set to "true" if needed)
export VI_GPU_SUMMARIZATION="false"         # Use GPU for summarization

# Node Selectors (Optional - match your node pool labels)
export VI_DEEPSTREAM_NODE_SELECTOR="deepstream"     # Node selector for deepstream workloads
export VI_SUMMARIZATION_NODE_SELECTOR="summarization" # Node selector for summarization

# GPU Tolerations
export VI_GPU_TOLERATIONS_KEY="nvidia.com/gpu"
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

**Example Output:**
```
Extension 'connectedk8s' is already installed.
Extension 'k8s-extension' is already installed.
Extension 'aks-preview' is already installed.
```

---

## Step 2: Create Resource Group

```bash
# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
az group create --name $RG --location $REGION --tags $TAGS
```

**Example Output:**
```json
{
  "id": "/subscriptions/12345678-.../resourceGroups/mycompany-vi-arc-rg",
  "location": "eastus",
  "name": "mycompany-vi-arc-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "createdBy": "mycompany-vi-arc",
    "purpose": "vi-arc-deployment"
  }
}
```

---

## Step 3: Create AKS Cluster ⏱️ ~5-10 min

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

**Example Output:**
```json
{
  "name": "mycompany-vi-arc-aks",
  "location": "eastus",
  "provisioningState": "Succeeded",
  "kubernetesVersion": "1.30.7",
  "nodeResourceGroup": "mycompany-vi-arc-aks-agentpool-rg",
  ...
}
```

### Add Maintenance Windows (Optional but Recommended)

Maintenance windows schedule automatic Kubernetes and node OS upgrades during specific times to minimize disruption. This is recommended for production environments to ensure updates happen during off-peak hours. For development/testing, you can skip this step. Adjust `--utc-offset` to match your timezone (e.g., `-08:00` for US West/PST).

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

**Example Output:**
```
NAME                                STATUS   ROLES    AGE   VERSION
aks-system-12345678-vmss000000      Ready    <none>   5m    v1.30.7
aks-system-12345678-vmss000001      Ready    <none>   5m    v1.30.7
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

**Example Output:**
```json
{
  "name": "workload",
  "vmSize": "Standard_D32a_v4",
  "count": 0,
  "minCount": 0,
  "maxCount": 10,
  "enableAutoScaling": true,
  "provisioningState": "Succeeded"
}
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

## Step 5: Install NVIDIA GPU Operator ⏱️ ~3-5 min

Install the NVIDIA GPU operator for GPU workloads:

```bash
# Add NVIDIA Helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install GPU operator
helm upgrade -i gpu-operator --wait -n gpu-operator --create-namespace \
    --version v25.10.01 \
    nvidia/gpu-operator --kube-context ${KUBECTL_CONTEXT}
```

**Example Output:**
```
Release "gpu-operator" does not exist. Installing it now.
NAME: gpu-operator
NAMESPACE: gpu-operator
STATUS: deployed
REVISION: 1
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

# Configure DNS label with random suffix (creates <dns-label>.<region>.cloudapp.azure.com)
az network public-ip update -g $NODEPOOL_RG -n ${RESOURCES_PREFIX}-inbound-ip \
    --dns-name ${DNS_LABEL}

FQDN="${DNS_LABEL}.${REGION}.cloudapp.azure.com"
echo "FQDN: ${FQDN}"
```

**Example Output:**
```
Public IP: 20.121.45.123
FQDN: mycompany-vi-arc456.eastus.cloudapp.azure.com
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

**Example Output:**
```
NAME    TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                      AGE
nginx   LoadBalancer   10.0.123.45    20.121.45.123   80:31234/TCP,443:31235/TCP   2m
```

---

## Step 7: Connect to Azure Arc ⏱️ ~3-5 min

Connect your AKS cluster to Azure Arc:

```bash
az connectedk8s connect --name ${CONNECTED_CLUSTER} --resource-group $RG --yes

# Verify connection
az connectedk8s show --name ${CONNECTED_CLUSTER} --resource-group $RG \
    --query "connectivityStatus" -o tsv
```

**Example Output:**
```
Connected
```

---

## Step 8: Install Cert Manager

Install the cert-manager extension required for Video Indexer Arc:

```bash
CM_EXT_NAME="azure-cert-manager"

az k8s-extension create \
    --cluster-name "${CONNECTED_CLUSTER}" \
    --name "${CM_EXT_NAME}" \
    --resource-group "${RG}" \
    --cluster-type connectedClusters \
    --extension-type Microsoft.CertManagement \
    --scope cluster

# Wait for extension to be ready
az k8s-extension show \
    --cluster-name "${CONNECTED_CLUSTER}" \
    --resource-group "${RG}" \
    --cluster-type connectedClusters \
    --name "${CM_EXT_NAME}" \
    --query "provisioningState" -o tsv
```

**Example Output:**
```
Succeeded
```

---

## Step 9: Deploy Video Indexer Arc Extension ⏱️ ~5-15 min

This step deploys the Video Indexer Arc extension to your cluster. Make sure you have set all the [Video Indexer Arc Extension Variables](#video-indexer-arc-extension-variables) before proceeding.

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
    --release-train "${VI_RELEASE_TRAIN}" \
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
    --config "storage.storageClass=azurefile-csi-premium" \
    --config "storage.accessMode=ReadWriteMany"
```

### Create Extension (Advanced Configuration with GPU Summarization)

For a deployment with GPU-based summarization features:

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
    --release-train "${VI_RELEASE_TRAIN}" \
    --auto-upgrade-minor-version "false" \
    --config "videoIndexer.accountId=${VI_ACCOUNT_ID}" \
    --config "videoIndexer.accountResourceId=${VI_ACCOUNT_RESOURCE_ID}" \
    --config "videoIndexer.endpointUri=${VI_ENDPOINT_URI}" \
    --config "videoIndexer.mediaUploadsEnabled=${VI_MEDIA_UPLOADS_ENABLED}" \
    --config "videoIndexer.liveVideoStreamEnabled=${VI_LIVE_VIDEO_ENABLED}" \
    --config "ViAi.LiveSummarization.enabled=true" \
    --config "ViAi.gpu.enabled=true" \
    --config "ViAi.gpu.tolerations.key=${VI_GPU_TOLERATIONS_KEY}" \
    --config "ViAi.deepstream.nodeSelector.workload=${VI_DEEPSTREAM_NODE_SELECTOR}" \
    --config "ViAi.summarization.nodeSelector.workload=${VI_SUMMARIZATION_NODE_SELECTOR}" \
    --config "storage.storageClass=azurefile-csi-premium" \
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

**Example Output:**
```json
{
  "name": "video-indexer",
  "provisioningState": "Succeeded",
  "version": "1.2.53"
}
```

```
NAME                                    READY   STATUS    RESTARTS   AGE
vi-api-server-5d8f9c7b8d-x2k4m          1/1     Running   0          5m
vi-speech-processor-6f7b8c9d4e-j3l5n    1/1     Running   0          5m
vi-video-processor-7g8c9d5e6f-k4m6p     1/1     Running   0          5m
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
    --release-train "${VI_RELEASE_TRAIN}" \
    --auto-upgrade-minor-version "false" \
    --config "videoIndexer.accountId=${VI_ACCOUNT_ID}" \
    --config "videoIndexer.accountResourceId=${VI_ACCOUNT_RESOURCE_ID}" \
    --config "videoIndexer.endpointUri=${VI_ENDPOINT_URI}" \
    --config "videoIndexer.mediaUploadsEnabled=${VI_MEDIA_UPLOADS_ENABLED}" \
    --config "videoIndexer.liveVideoStreamEnabled=${VI_LIVE_VIDEO_ENABLED}" \
    --config "ViAi.LiveSummarization.enabled=${VI_LIVE_SUMMARIZATION_ENABLED}" \
    --config "ViAi.gpu.enabled=${VI_GPU_SUMMARIZATION}" \
    --config "ViAi.gpu.tolerations.key=${VI_GPU_TOLERATIONS_KEY}" \
    --config "storage.storageClass=azurefile-csi-premium" \
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
| `ViAi.LiveSummarization.enabled` | Enable live summarization | No | false |
| `ViAi.gpu.enabled` | Use GPU for summarization | No | false |
| `ViAi.gpu.tolerations.key` | GPU node taint key | No | nvidia.com/gpu |
| `storage.storageClass` | Kubernetes storage class | No | azurefile-csi-premium |
| `storage.accessMode` | Storage access mode | No | ReadWriteMany |

---

## DNS and SSL Configuration

### DNS Options

You have two options for DNS:

1. **Azure Public DNS Label** (Automatic): Use the Azure-provided FQDN:
   ```
   <your-dns-label>.<region>.cloudapp.azure.com
   ```
   > **Note**: The DNS label must be unique per region. This guide uses a random suffix to avoid collisions.

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
