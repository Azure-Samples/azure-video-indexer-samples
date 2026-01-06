# Video Indexer Arc - AKS Cluster Setup Guide

This guide provides step-by-step instructions for creating an Azure Kubernetes Service (AKS) cluster configured for Video Indexer Arc deployment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Configuration Variables](#configuration-variables)
- [Step 1: Install CLI Tools](#step-1-install-cli-tools)
- [Step 2: Create Resource Group](#step-2-create-resource-group)
- [Step 3: Create AKS Cluster](#step-3-create-aks-cluster)
- [Step 4: Add Node Pools](#step-4-add-node-pools)
- [Step 5: Install NVIDIA GPU Operator](#step-5-install-nvidia-gpu-operator)
- [Step 6: Configure Ingress Controller](#step-6-configure-ingress-controller)
- [Step 7: Connect to Azure Arc](#step-7-connect-to-azure-arc)
- [Step 8: Install Cert Manager](#step-8-install-cert-manager)
- [DNS and SSL Configuration](#dns-and-ssl-configuration)
- [Verification](#verification)

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

After completing cluster setup:

1. Deploy the Video Indexer Arc extension
2. Configure the extension with your cluster settings
3. Verify the extension is running properly

For extension deployment, refer to the Video Indexer Arc deployment documentation.

---

## Troubleshooting

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
