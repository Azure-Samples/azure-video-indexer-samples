#!/bin/bash

set -e

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ VI Arc AKS Cluster Creation Script @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# This script creates an AKS cluster for Video Indexer Arc deployment.
# 
# Node Pools Created:
# - system: System nodes for Kubernetes components
# - workload: General workload nodes for VI services
# - gpudeepstrm: GPU nodes for deepstream/live pipeline workloads (optional)
# - gpusumm: GPU nodes for summarization workloads (optional - if summarization feature is needed)
# - workloadf32: CPU nodes for summarization workloads (alternative to GPU summarization)
#===========================================================================================================#

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AKS CLUSTER CONFIGURATION @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Use these variables to create a new AKS cluster for Video Indexer Arc
#===========================================================================================================#

# REQUIRED: Your Azure subscription ID
subscriptionId="<YOUR_SUBSCRIPTION_ID>"

# REQUIRED: Azure region for deployment (e.g., eastus, westus2, westeurope)
region="<YOUR_AZURE_REGION>"

# REQUIRED: Resource naming prefix (used for all resources)
resourcesPrefix="<YOUR_PREFIX>"

# Generate random suffix to avoid DNS collisions (Azure public DNS requires unique names per region)
# Storage account names: max 24 lowercase letters/numbers
# DNS labels: must be unique per region
randomSuffix=$(shuf -i 100-999 -n 1 2>/dev/null || echo $((RANDOM % 900 + 100)))

# Derived names (modify if you prefer different naming)
rg="${resourcesPrefix}-rg"
aks="${resourcesPrefix}-aks"
connectedClusterName="${resourcesPrefix}-connected-aks"
nodePoolRg="${aks}-agentpool-rg"
tags="createdBy=${resourcesPrefix} purpose=vi-arc-deployment"

# DNS label with random suffix to avoid collisions
dnsLabel="${resourcesPrefix}${randomSuffix}"

# Kubectl context name for this cluster
kubectlContext="${resourcesPrefix}"

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AKS VM Sizes @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

# System node VM size (4 vcpus, 16 GB RAM recommended)
nodeVmSize="Standard_D4a_v4"

# General workload VM size (32 vcpus, 128 GB RAM recommended)
workerVmSize="Standard_D32a_v4"

# CPU summarization VM size (32 vcpus, 64 GB RAM recommended)
summarizationWorkerVmSize="Standard_F32s_v2"

# GPU VM size for deepstream, agents, and summarization
# Options (choose based on availability and quota in your region):
#   - Standard_NC40ads_H100_v5 (1 H100 GPU) - Best performance
#   - Standard_NC24ads_A100_v4 (1 A100 GPU) - High performance
#   - Standard_NV36ads_A10_v5 (1 A10 GPU) - Cost-effective
# Check quota with: az vm list-usage --location $region -o table | grep -i "<GPU_TYPE>"
gpuVmSize="Standard_NC40ads_H100_v5"

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AKS Feature Flags @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

# Set to "true" to install GPU node pools for summarization
enableSummarizationGpu="false"

# Set to "true" to install CPU node pools for summarization (alternative to GPU)
enableSummarizationCpu="false"

# Set to "true" to enable SSL/TLS with a certificate from Azure Key Vault
enableSsl="false"

# If enableSsl is true, provide your Key Vault certificate URI
# Format: https://<your-keyvault>.vault.azure.net/certificates/<certificate-name>
sslKeyVaultCertificateUri=""

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ VIDEO INDEXER ARC EXTENSION CONFIGURATION @@@@@@@@@@@@@@@@@@@@@@@@@@
# Use these variables to install the VI extension on any Arc-connected Kubernetes cluster
#===========================================================================================================#

# Extension naming
extensionName="video-indexer"
namespace="video-indexer"

# REQUIRED: Extension version - Get the latest version number
viExtensionVersion="<YOUR_EXTENSION_VERSION>"  # e.g., "1.2.53"

# Release train configuration
# NOTE: Currently using preview release train. Change to "stable" when stable versions are released.
viReleaseTrain="preview"  # Options: "preview" or "stable" (use "stable" for production when available)

# REQUIRED: Video Indexer Account Information
viAccountId="<YOUR_VI_ACCOUNT_ID>"              # Your Video Indexer account ID (GUID)
viAccountResourceId="<YOUR_VI_ACCOUNT_RESOURCE_ID>"  # Full ARM resource ID
# Format: /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.VideoIndexer/accounts/<account-name>

# Extension Feature Flags
viLiveVideoEnabled="true"           # Enable live video stream processing
viMediaUploadsEnabled="true"        # Enable media file uploads
viLiveSummarizationEnabled="false"  # Enable live summarization (disabled for basic configuration)
viGpuSummarization="false"          # Use GPU for summarization

# GPU Tolerations
viGpuTolerationsKey="nvidia.com/gpu"

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Installation Flags @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

install_aks_cluster="true"
install_cli_tools="true"

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Helper Functions @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

export valid_regions=($(az account list-locations --query "[].name" -o tsv 2>/dev/null || echo ""))

function is_valid_azure_region() {
    local location=$1
    for region in "${valid_regions[@]}"; do
        if [[ $region == $location ]]; then
            return 0
        fi
    done
    return 1
}

function print_local_regions() {
    for region in "${valid_regions[@]}"; do
        echo $region
    done
}

function install_cli_tools() {
    echo "Installing/updating Azure CLI extensions..."
    az extension add --name connectedk8s --upgrade --yes 2>/dev/null || az extension add --name connectedk8s
    az extension add --name k8s-extension --upgrade --yes 2>/dev/null || az extension add --name k8s-extension
    az extension add --name aks-preview --upgrade --yes 2>/dev/null || az extension add --name aks-preview
    
    echo "Registering required Azure providers..."
    az provider register --namespace Microsoft.Kubernetes
    az provider register --namespace Microsoft.KubernetesConfiguration
    az provider register --namespace Microsoft.ExtendedLocation
    echo "CLI tools setup complete."
}

function validate_aks_configuration() {
    local errors=0
    
    if [[ "$subscriptionId" == "<YOUR_SUBSCRIPTION_ID>" ]] || [[ -z "$subscriptionId" ]]; then
        echo "ERROR: Please set your Azure subscription ID in 'subscriptionId' variable"
        errors=$((errors + 1))
    fi
    
    if [[ "$region" == "<YOUR_AZURE_REGION>" ]] || [[ -z "$region" ]]; then
        echo "ERROR: Please set your Azure region in 'region' variable"
        errors=$((errors + 1))
    fi
    
    if [[ "$resourcesPrefix" == "<YOUR_PREFIX>" ]] || [[ -z "$resourcesPrefix" ]]; then
        echo "ERROR: Please set your resource prefix in 'resourcesPrefix' variable"
        errors=$((errors + 1))
    fi
    
    if [[ "$enableSsl" == "true" ]] && [[ -z "$sslKeyVaultCertificateUri" ]]; then
        echo "ERROR: SSL is enabled but 'sslKeyVaultCertificateUri' is not set"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "Please edit the AKS CLUSTER CONFIGURATION section at the top of this script and try again."
        return 1
    fi
    return 0
}

function validate_extension_configuration() {
    local errors=0
    
    if [[ "$viExtensionVersion" == "<YOUR_EXTENSION_VERSION>" ]] || [[ -z "$viExtensionVersion" ]]; then
        echo "ERROR: Please set the VI extension version in 'viExtensionVersion' variable"
        errors=$((errors + 1))
    fi
    
    if [[ "$viAccountId" == "<YOUR_VI_ACCOUNT_ID>" ]] || [[ -z "$viAccountId" ]]; then
        echo "ERROR: Please set your Video Indexer account ID in 'viAccountId' variable"
        errors=$((errors + 1))
    fi
    
    if [[ "$viAccountResourceId" == "<YOUR_VI_ACCOUNT_RESOURCE_ID>" ]] || [[ -z "$viAccountResourceId" ]]; then
        echo "ERROR: Please set your Video Indexer account resource ID in 'viAccountResourceId' variable"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "Please edit the VIDEO INDEXER ARC EXTENSION CONFIGURATION section at the top of this script and try again."
        return 1
    fi
    return 0
}

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Main Script @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

echo "================================================================"
echo "============= VI Arc AKS Cluster Configuration ================="
echo "================================================================"

# Validate configuration before proceeding
validate_aks_configuration || exit 1
validate_extension_configuration || exit 1

echo "SubscriptionId: ${subscriptionId}"
echo "Resource Group: ${rg}"
echo "AKS Cluster Name: ${aks}"
echo "Connected Cluster Name: ${connectedClusterName}"
echo "Region: ${region}"
echo "DNS Label: ${dnsLabel} (includes random suffix to avoid collisions)"
echo ""
echo "Features Enabled:"
echo "  - GPU Summarization: ${enableSummarizationGpu}"
echo "  - CPU Summarization: ${enableSummarizationCpu}"
echo "  - SSL/TLS: ${enableSsl}"
echo ""
echo "Extension Configuration:"
echo "  - Release Train: ${viReleaseTrain} (change to 'stable' when stable versions are available)"
echo "  - Live Summarization: ${viLiveSummarizationEnabled}"
echo "================================================================"

read -p "Do you want to proceed with cluster creation? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Cluster creation cancelled."
    exit 0
fi

# Region validation
region=${region,,}
if [[ ${#valid_regions[@]} -gt 0 ]] && ! is_valid_azure_region "$region"; then
    echo "Invalid Azure region $region. Use one of the following regions:"
    print_local_regions
    exit 1
fi

# Get latest AKS version
aksVersion=$(az aks get-versions --location $region --query "values[].patchVersions.keys(@)[][] | sort(@) | [-1]" | tr -d '"')
echo "Latest AKS Version: ${aksVersion}"

if [[ -z ${aksVersion} ]]; then
    echo "Failed to get AKS version. Run 'az aks get-versions --location $region' to debug."
    exit 1
fi

echo "Switching to subscription: $subscriptionId"
az account set --subscription $subscriptionId

# Install CLI tools if needed
if [[ $install_cli_tools == "true" ]]; then
    install_cli_tools
fi

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Infrastructure @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

if [[ $install_aks_cluster == "true" ]]; then
    echo "================================================================"
    echo "============= Deploying AKS Resources =========================="
    echo "================================================================"

    # Create Resource Group
    echo "Creating Resource Group: $rg"
    az group create --name $rg --location $region --output table --tags $tags

    #=======================================================================#
    #======== Create AKS Cluster ===========================================#
    #=======================================================================#
    clusterExists=$(az aks show -n $aks -g $rg --query "name" -o tsv 2>/dev/null || true)
    if [[ ! -z $clusterExists ]]; then
        echo "AKS Cluster $aks already exists. Skipping AKS Cluster creation"
    else
        echo "Creating AKS cluster: $aks"
        az aks create -n $aks -g $rg \
            --enable-managed-identity \
            --enable-workload-identity \
            --enable-addons azure-keyvault-secrets-provider \
            --kubernetes-version ${aksVersion} \
            --enable-oidc-issuer \
            --nodepool-name system \
            --os-sku AzureLinux \
            --node-count 2 \
            --tier standard \
            --generate-ssh-keys \
            --network-plugin kubenet \
            --tags $tags \
            --node-resource-group $nodePoolRg \
            --node-vm-size $nodeVmSize \
            --enable-image-cleaner --image-cleaner-interval-hours 24 \
            --node-os-upgrade-channel NodeImage --auto-upgrade-channel node-image

        if [[ $? -eq 0 ]]; then
            echo "AKS cluster creation succeeded"
        else
            echo "AKS cluster creation failed."
            exit 1
        fi
        
        # Add maintenance windows - schedules automatic upgrades during off-peak hours
        # Recommended for production. Adjust --utc-offset for your timezone (e.g., -08:00 for US West/PST)
        az aks maintenanceconfiguration add --resource-group $rg --cluster-name $aks \
            --name aksManagedAutoUpgradeSchedule --schedule-type Weekly \
            --day-of-week Friday --interval-weeks 3 --duration 8 \
            --utc-offset +00:00 --start-time 00:00
        
        az aks maintenanceconfiguration add --resource-group $rg --cluster-name $aks \
            --name aksManagedNodeOSUpgradeSchedule --schedule-type Weekly \
            --day-of-week Friday --interval-weeks 1 --duration 8 \
            --utc-offset +00:00 --start-time 00:00
    fi
    echo "AKS cluster ready: $aks"

    #=======================================================================#
    #======== Add General Workload Node Pool ===============================#
    #=======================================================================#
    echo "Adding general workload node pool..."
    nodePoolExists=$(az aks nodepool show -g $rg --cluster-name $aks -n workload --query "name" -o tsv 2>/dev/null || true)
    if [[ ! -z $nodePoolExists ]]; then
        echo "Workload node pool already exists. Skipping."
    else
        az aks nodepool add -g $rg --cluster-name $aks -n workload \
            --os-sku AzureLinux \
            --mode User \
            --node-vm-size $workerVmSize \
            --node-osdisk-size 100 \
            --node-count 0 \
            --max-count 10 \
            --min-count 0 \
            --tags $tags \
            --enable-cluster-autoscaler \
            --max-pods 110
        echo "Workload node pool created."
    fi

    #=======================================================================#
    #======== Add CPU Summarization Node Pool (Optional) ===================#
    #=======================================================================#
    if [[ "$enableSummarizationCpu" == "true" ]]; then
        echo "Adding CPU summarization node pool (workloadf32)..."
        nodePoolSummarizationExists=$(az aks nodepool show -g $rg --cluster-name $aks -n workloadf32 --query "name" -o tsv 2>/dev/null || true)
        if [[ ! -z $nodePoolSummarizationExists ]]; then
            echo "workloadf32 node pool already exists. Skipping."
        else
            az aks nodepool add -g $rg --cluster-name $aks -n workloadf32 \
                --os-sku AzureLinux \
                --mode User \
                --node-vm-size $summarizationWorkerVmSize \
                --node-osdisk-size 100 \
                --node-count 0 \
                --max-count 5 \
                --min-count 0 \
                --tags $tags \
                --enable-cluster-autoscaler \
                --labels workload=summarization \
                --max-pods 110
            echo "CPU summarization node pool created."
        fi
    fi

    #=======================================================================#
    #======== GPU Node Pool: Deepstream ====================================#
    #=======================================================================#
    echo "Adding GPU node pool for Deepstream (live pipeline)..."
    gpuDeepstreamExists=$(az aks nodepool show -g $rg --cluster-name $aks -n gpudeepstrm --query "name" -o tsv 2>/dev/null || true)
    if [[ ! -z $gpuDeepstreamExists ]]; then
        echo "gpudeepstrm node pool already exists. Skipping."
    else
        az aks nodepool add -g $rg --cluster-name $aks -n gpudeepstrm \
            --os-sku Ubuntu \
            --mode User \
            --node-vm-size $gpuVmSize \
            --node-osdisk-size 200 \
            --node-count 0 \
            --max-count 1 \
            --min-count 0 \
            --tags $tags \
            --enable-cluster-autoscaler \
            --node-taints nvidia.com/gpu=true:NoSchedule \
            --labels workload=deepstream \
            --max-pods 110
        echo "Deepstream GPU node pool created."
    fi

    #=======================================================================#
    #======== GPU Node Pool: Summarization (Optional) ======================#
    #=======================================================================#
    if [[ "$enableSummarizationGpu" == "true" ]]; then
        echo "Adding GPU node pool for Summarization..."
        gpuSummarizationExists=$(az aks nodepool show -g $rg --cluster-name $aks -n gpusumm --query "name" -o tsv 2>/dev/null || true)
        if [[ ! -z $gpuSummarizationExists ]]; then
            echo "gpusumm node pool already exists. Skipping."
        else
            az aks nodepool add -g $rg --cluster-name $aks -n gpusumm \
                --os-sku Ubuntu \
                --mode User \
                --node-vm-size $gpuVmSize \
                --node-osdisk-size 200 \
                --node-count 0 \
                --max-count 1 \
                --min-count 0 \
                --tags $tags \
                --enable-cluster-autoscaler \
                --node-taints nvidia.com/gpu=true:NoSchedule \
                --labels workload=summarization \
                --max-pods 110
            echo "Summarization GPU node pool created."
        fi
    fi

    #=============================================#
    #============== AKS Credentials ==============#
    #=============================================#
    echo "Getting AKS credentials..."
    az aks get-credentials --resource-group $rg --name $aks --admin --overwrite-existing --context ${kubectlContext}
    # Rename context to remove -admin suffix
    kubectl config rename-context ${kubectlContext}-admin ${kubectlContext} 2>/dev/null || true
    
    echo "Verifying cluster connectivity..."
    kubectl get nodes --context ${kubectlContext}

    #=======================================================================#
    #======== Install NVIDIA GPU Operator ==================================#
    #=======================================================================#
    echo "Installing NVIDIA GPU Operator..."
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 2>/dev/null || true
    helm repo update
    
    # Install GPU operator with default values from NVIDIA
    helm upgrade -i gpu-operator --wait -n gpu-operator --create-namespace \
        --version v25.3.2 \
        nvidia/gpu-operator --kube-context ${kubectlContext}
    echo "NVIDIA GPU Operator installed."

    #=============================================#
    #============== Add Ingress Controller =======#
    #=============================================#
    echo "Setting up ingress controller..."
    
    # Create Public IP
    publicIpExists=$(az network public-ip show -g $nodePoolRg -n ${resourcesPrefix}-inbound-ip --query "name" -o tsv 2>/dev/null || true)
    if [[ -z $publicIpExists ]]; then
        echo "Creating Public IP for Ingress Controller"
        az network public-ip create -g $nodePoolRg -n ${resourcesPrefix}-inbound-ip \
            --sku Standard --allocation-method static --output table
    else
        echo "Public IP already exists. Skipping creation."
    fi
    
    # Get the public IP address
    PUBLIC_IP=$(az network public-ip show -g $nodePoolRg -n ${resourcesPrefix}-inbound-ip --query ipAddress -o tsv)
    echo "Public IP: ${PUBLIC_IP}"
    
    # Configure DNS label for public IP with random suffix (creates <dns-label>.<region>.cloudapp.azure.com)
    EXPECTED_FQDN="${dnsLabel}.${region}.cloudapp.azure.com"
    
    echo "Configuring DNS label with random suffix to avoid collisions..."
    az network public-ip update \
        -g $nodePoolRg \
        -n ${resourcesPrefix}-inbound-ip \
        --dns-name ${dnsLabel}
    
    echo "DNS FQDN: ${EXPECTED_FQDN}"
    
    # Enable app routing on AKS
    approutingEnabled=$(az aks show -g $rg -n $aks --query "ingressProfile.webAppRouting.enabled" -o tsv 2>/dev/null || true)
    if [[ "$approutingEnabled" != "true" ]]; then
        echo "Enabling app routing on AKS cluster..."
        if [[ "$enableSsl" == "true" ]]; then
            # Get Key Vault ID from the URI
            kvName=$(echo $sslKeyVaultCertificateUri | sed -n 's|https://\([^.]*\)\.vault\.azure\.net.*|\1|p')
            KEYVAULTID=$(az keyvault show --name $kvName --query "id" --output tsv)
            az aks approuting enable -g $rg -n $aks --enable-kv --attach-kv $KEYVAULTID
        else
            az aks approuting enable -g $rg -n $aks
        fi
    fi
    
    # Create nginx ingress controller configuration
    echo "Creating nginx ingress controller configuration..."
    
    if [[ "$enableSsl" == "true" ]]; then
        # With SSL certificate from Key Vault
        cat <<EOF | kubectl apply -f - --context ${kubectlContext}
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: nginx
spec:
  ingressClassName: nginx
  controllerNamePrefix: nginx
  loadBalancerAnnotations: 
    service.beta.kubernetes.io/azure-pip-name: ${resourcesPrefix}-inbound-ip
    service.beta.kubernetes.io/azure-load-balancer-resource-group: ${nodePoolRg}
  defaultSSLCertificate:
    keyVaultURI: "${sslKeyVaultCertificateUri}"
EOF
    else
        # Without SSL (HTTP only)
        cat <<EOF | kubectl apply -f - --context ${kubectlContext}
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: nginx
spec:
  ingressClassName: nginx
  controllerNamePrefix: nginx
  loadBalancerAnnotations: 
    service.beta.kubernetes.io/azure-pip-name: ${resourcesPrefix}-inbound-ip
    service.beta.kubernetes.io/azure-load-balancer-resource-group: ${nodePoolRg}
EOF
    fi
    
    # Wait for nginx to get external IP
    echo "Waiting for nginx ingress to get external IP..."
    for i in {1..30}; do
        NGINX_IP=$(kubectl get svc nginx -n app-routing-system --context ${kubectlContext} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
        if [[ "$NGINX_IP" == "$PUBLIC_IP" ]]; then
            echo "Nginx ingress controller configured with IP: ${NGINX_IP}"
            break
        fi
        echo "  Waiting for external IP... (attempt ${i}/30)"
        sleep 10
    done

    #=============================================#
    #======== Create Arc Connected Cluster =======#
    #=============================================#
    echo "Connecting AKS to Azure Arc..."
    connectedClusterExists=$(az connectedk8s show --name ${connectedClusterName} --resource-group $rg --query "name" -o tsv 2>/dev/null || true)
    if [[ -z $connectedClusterExists ]]; then
        az connectedk8s connect --name ${connectedClusterName} --resource-group $rg --yes
    else
        echo "Arc connected cluster already exists. Skipping."
    fi
    
    # Verify Arc connection
    echo "Verifying Arc connection..."
    az connectedk8s show --name ${connectedClusterName} --resource-group $rg --query "connectivityStatus" -o tsv

    #=============================================#
    #======== Install Cert Manager Extension =====#
    #=============================================#
    echo "Installing cert-manager extension..."
    cm_ext_name="${aks}-certmgr"
    
    cm_exists=$(
        az k8s-extension list \
            --cluster-name "${connectedClusterName}" \
            --resource-group "${rg}" \
            --cluster-type connectedClusters \
            --query "[?name=='${cm_ext_name}' || (extensionType=='microsoft.iotoperations.platform' && releaseNamespace=='cert-manager')].name" \
            -o tsv
    )
    
    if [[ -n "${cm_exists}" ]]; then
        echo "cert-manager extension already installed. Skipping."
    else
        az k8s-extension create \
            --cluster-name "${connectedClusterName}" \
            --name "${cm_ext_name}" \
            --resource-group "${rg}" \
            --cluster-type connectedClusters \
            --extension-type microsoft.iotoperations.platform \
            --scope cluster \
            --release-namespace cert-manager
        
        # Wait for extension to be ready
        echo "Waiting for cert-manager extension..."
        for i in {1..30}; do
            state=$(az k8s-extension show \
                --cluster-name "${connectedClusterName}" \
                --resource-group "${rg}" \
                --cluster-type connectedClusters \
                --name "${cm_ext_name}" \
                --query "provisioningState" -o tsv 2>/dev/null || true)
            [[ "${state}" == "Succeeded" || "${state}" == "ProvisioningSucceeded" ]] && break
            echo "  Status: ${state:-unknown} (retry ${i}/30)"
            sleep 10
        done
    fi
    #===========================================================================================================#
    #======== Install Video Indexer Arc Extension =============================================================#
    #===========================================================================================================#
    echo ""
    echo "================================================================"
    echo "============= Installing Video Indexer Arc Extension ==========="
    echo "================================================================"
    
    # Set the endpoint URI based on SSL configuration
    if [[ "$enableSsl" == "true" ]]; then
        viEndpointUri="https://${EXPECTED_FQDN}"
    else
        viEndpointUri="http://${EXPECTED_FQDN}"
    fi
    
    # Check if extension already exists
    viExtExists=$(az k8s-extension show \
        --name "${extensionName}" \
        --cluster-name "${connectedClusterName}" \
        --resource-group "${rg}" \
        --cluster-type "connectedClusters" \
        --query "name" -o tsv 2>/dev/null || true)
    
    if [[ -n "${viExtExists}" ]]; then
        echo "Video Indexer extension already exists. Updating..."
        
        # Build the update command
        updateCmd="az k8s-extension update \
            --name ${extensionName} \
            --cluster-name ${connectedClusterName} \
            --resource-group ${rg} \
            --cluster-type connectedClusters \
            --version ${viExtensionVersion} \
            --release-train ${viReleaseTrain} \
            --auto-upgrade-minor-version false \
            --config videoIndexer.accountId=${viAccountId} \
            --config videoIndexer.accountResourceId=${viAccountResourceId} \
            --config videoIndexer.endpointUri=${viEndpointUri} \
            --config videoIndexer.mediaUploadsEnabled=${viMediaUploadsEnabled} \
            --config videoIndexer.liveVideoStreamEnabled=${viLiveVideoEnabled} \
            --config ViAi.LiveSummarization.enabled=${viLiveSummarizationEnabled} \
            --config ViAi.gpu.enabled=${viGpuSummarization} \
            --config ViAi.gpu.tolerations.key=${viGpuTolerationsKey} \
            --config ViAi.deepstream.nodeSelector.workload=deepstream \
            --config storage.storageClass=azurefile-csi-premium \
            --config storage.accessMode=ReadWriteMany \
            --yes"
        
        # Add summarization node selector if GPU summarization is enabled
        if [[ "$enableSummarizationGpu" == "true" ]] || [[ "$enableSummarizationCpu" == "true" ]]; then
            updateCmd="${updateCmd} \
            --config ViAi.summarization.nodeSelector.workload=summarization"
        fi
        
        eval $updateCmd
    else
        echo "Creating Video Indexer extension..."
        
        # Build the create command
        createCmd="az k8s-extension create \
            --name ${extensionName} \
            --extension-type Microsoft.videoIndexer \
            --scope cluster \
            --release-namespace video-indexer \
            --cluster-name ${connectedClusterName} \
            --resource-group ${rg} \
            --cluster-type connectedClusters \
            --version ${viExtensionVersion} \
            --release-train ${viReleaseTrain} \
            --auto-upgrade-minor-version false \
            --config videoIndexer.accountId=${viAccountId} \
            --config videoIndexer.accountResourceId=${viAccountResourceId} \
            --config videoIndexer.endpointUri=${viEndpointUri} \
            --config videoIndexer.mediaUploadsEnabled=${viMediaUploadsEnabled} \
            --config videoIndexer.liveVideoStreamEnabled=${viLiveVideoEnabled} \
            --config ViAi.LiveSummarization.enabled=${viLiveSummarizationEnabled} \
            --config ViAi.gpu.enabled=${viGpuSummarization} \
            --config ViAi.gpu.tolerations.key=${viGpuTolerationsKey} \
            --config ViAi.deepstream.nodeSelector.workload=deepstream \
            --config storage.storageClass=azurefile-csi-premium \
            --config storage.accessMode=ReadWriteMany"
        
        # Add summarization node selector if GPU summarization is enabled
        if [[ "$enableSummarizationGpu" == "true" ]] || [[ "$enableSummarizationCpu" == "true" ]]; then
            createCmd="${createCmd} \
            --config ViAi.summarization.nodeSelector.workload=summarization"
        fi
        
        eval $createCmd
    fi
    
    # Wait for extension to be ready
    echo "Waiting for Video Indexer extension to be ready..."
    for i in {1..60}; do
        state=$(az k8s-extension show \
            --name "${extensionName}" \
            --cluster-name "${connectedClusterName}" \
            --resource-group "${rg}" \
            --cluster-type "connectedClusters" \
            --query "provisioningState" -o tsv 2>/dev/null || true)
        
        if [[ "${state}" == "Succeeded" ]]; then
            echo "Video Indexer extension installed successfully!"
            break
        elif [[ "${state}" == "Failed" ]]; then
            echo "ERROR: Video Indexer extension installation failed."
            echo "Check the extension status for more details:"
            echo "  az k8s-extension show --name ${extensionName} --cluster-name ${connectedClusterName} --resource-group ${rg} --cluster-type connectedClusters"
            break
        fi
        
        echo "  Status: ${state:-unknown} (retry ${i}/60)"
        sleep 10
    done
    
    # Verify pods are running
    echo "Verifying Video Indexer pods..."
    kubectl get pods -n video-indexer --context ${kubectlContext}
fi

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Completion Summary @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

echo ""
echo "================================================================"
echo "============= Cluster Setup Complete ==========================="
echo "================================================================"
echo ""
echo "Cluster Details:"
echo "  Resource Group: ${rg}"
echo "  AKS Cluster: ${aks}"
echo "  Connected Cluster: ${connectedClusterName}"
echo "  Region: ${region}"
echo "  Kubectl Context: ${kubectlContext}"
echo ""
echo "DNS Configuration:"
echo "  Public IP: ${PUBLIC_IP}"
echo "  FQDN: ${EXPECTED_FQDN}"
echo "  (DNS label includes random suffix '${randomSuffix}' to avoid collisions)"
echo ""
echo "Node Pools Created:"
echo "  - system: System nodes (${nodeVmSize})"
echo "  - workload: General workload (autoscale 0-10, ${workerVmSize})"
echo "  - gpudeepstrm: GPU for deepstream (autoscale 0-1, ${gpuVmSize})"
if [[ "$enableSummarizationGpu" == "true" ]]; then
    echo "  - gpusumm: GPU for summarization (autoscale 0-1, ${gpuVmSize})"
fi
if [[ "$enableSummarizationCpu" == "true" ]]; then
    echo "  - workloadf32: CPU for summarization (autoscale 0-5, ${summarizationWorkerVmSize})"
fi
echo ""
echo "SSL Configuration: ${enableSsl}"
if [[ "$enableSsl" == "true" ]]; then
    echo "  Certificate URI: ${sslKeyVaultCertificateUri}"
fi
echo ""
echo "Video Indexer Extension:"
echo "  Extension Name: ${extensionName}"
echo "  Extension Version: ${viExtensionVersion}"
echo "  Release Train: ${viReleaseTrain} (change to 'stable' when stable versions are available)"
echo "  Endpoint URI: ${viEndpointUri}"
echo "  Account ID: ${viAccountId}"
echo "  Live Video: ${viLiveVideoEnabled}"
echo "  Media Uploads: ${viMediaUploadsEnabled}"
echo "  Live Summarization: ${viLiveSummarizationEnabled}"
echo ""
echo "Next Steps:"
echo "  1. Access the Video Indexer portal at: ${viEndpointUri}"
echo "  2. Test live video stream processing with a camera source"
echo "  3. Upload test media files to verify indexing"
echo ""
echo "To connect to the cluster:"
echo "  kubectl config use-context ${kubectlContext}"
echo ""
echo "To check Video Indexer pods:"
echo "  kubectl get pods -n video-indexer --context ${kubectlContext}"
echo ""
echo "================================================================"
