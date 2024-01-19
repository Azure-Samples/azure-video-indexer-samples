#!/bin/bash

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Helper Functions @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#######################################
# region validation
# Ensure the user uses legal azure region name
#######################################
export valid_regions=($(az account list-locations --query "[].name" -o tsv))
function is_valid_azure_region() {
    local location=$1
    for reg in "${valid_regions[@]}"; do
        if [[ $reg == $location ]]; then
            return 0
        fi
    done
    return 1
}
function print_local_regions() {
  for reg in "${valid_regions[@]}"; do
    echo $reg
  done
}
#################################################
# get_parameter_value 
# Function to ask a question and read user's input
##############################################
function get_parameter_value () {
    local question="$1"
    local variable="$2"

    read -p "$question: " input
    if [[ -n $input ]]; then
        eval "$variable=\"$input\""
    fi
}

##############################################
#  CLI Pre-requisites
###############################################
function install_cli_tools {
  # https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
  echo "ensure you got the latest CLI client and install add ons if needed"
  echo "https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli"
  az extension add --name connectedk8s
  az extension add --name aks-preview
  az provider register --namespace Microsoft.Kubernetes
  az provider register --namespace Microsoft.KubernetesConfiguration
  az provider register --namespace Microsoft.ExtendedLocation
}

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Main Script @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#=============================================#
#============== Constants           ==========#
#=============================================#
install_cli_tools="true"
register_cli_add_ons="true"
aksVersion="1.27.3" # https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
viApiVersion="2023-06-02-preview" # VI API version

#=============================================#
#============== Parameters Customization =====#
#=============================================#
region="eastus" #default region , will be override later
resourcesPrefix="vi" #default resources prefix , will be override later
namespace="video-indexer" #default namespace , will be override later

# Ask questions and read user input
get_parameter_value "What is the Azure subscription ID during deployment?" "subscriptionId"
get_parameter_value "Provide a unique identifier value during deployment.(this will be used for Cloud Resources : AKS, DNS names etc)?" "resourcesPrefix"
get_parameter_value "What is the extension kubernetes namespace to install to ?" "namespace"

## Region Name Validation
region=${region,,}
if ! is_valid_azure_region "$region"; then
  echo "Invalid Azure region $region. Use one of the following regions:"
  print_local_regions
  exit 1
fi
echo "SubscriptionId: $subscriptionId"
echo "Azure Resource Group: ${resourceGroup}"
echo "Azure Resource prefixes: ${resourcesPrefix}"
echo "Region: $region"
echo "switching to $subscriptionId"
az account set --subscription $subscriptionId
#==============================================#

aks="${resourcesPrefix}-aks"
rg="${resourcesPrefix}-rg"
connectedClusterName="${resourcesPrefix}-connected-aks"
nodePoolRg="${aks}-agentpool-rg"
nodeVmSize="Standard_D4a_v4" # 4 vcpus, 16 GB RAM
workerVmSize="Standard_D32a_v4" # 32 vcpus, 128 GB RAM
tags="createdBy=vi-arc-extension"
#=========Install CLI Tools if needed =====================#
if [[ $install_cli_tools == "true" ]]; then
  install_cli_tools
fi

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Infra @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#
echo "================================================================"
echo "========== Deploying new AKS and ARC Enabled Resources ========="
echo "================================================================"

echo "Deploying Resources: [Resource group: $rg, AKS: $aks, Connected-Cluster Name: ${connectedClusterName}]"
echo "create Resource group"
az group create --name $rg --location $region --output table --tags $tags

#=======================================================================#
#======== Create AKS Cluster( Simulates User On Prem Infra) ============#
#=======================================================================#
echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***start***"
az aks create -n $aks -g $rg \
    --enable-managed-identity\
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
    --node-os-upgrade-channel NodeImage --auto-upgrade-channel node-image

echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***done***"
echo "Adding another worload node pool"
az aks nodepool add -g $rg --cluster-name $aks  -n workload \
        --os-sku AzureLinux \
        --mode User \
        --node-vm-size $workerVmSize \
        --node-osdisk-size 100 \
        --node-count 0 \
        --max-count 10 \
        --min-count 0  \
        --tags $tags \
        --enable-cluster-autoscaler \
        --max-pods 110
echo "Adding another workload node pool ***done***"
#=============================================#
#============== AKS Credentials ==============#
#=============================================#
echo -e  "\tConnecting to AKS and getting credentials  - ***start***"
az aks get-credentials --resource-group $rg --name $aks --admin --overwrite-existing
echo "AKS connectivity Sanity test"
kubectl get nodes
echo -e "\tconnect aks cluster - ***done***"
#=============================================#
#============== Add ingress controller =======#
#=============================================#
echo -e "\tAdding ingress controller -- ***start***"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
echo -e "\tAdding ingress controller -- ***done***"
#=============================================#
#========= Patch Public IP DNS Label =========
#=============================================#    
publicIpResourceId=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].id" -otsv)
echo "publicIpResourceId: $publicIpResourceId"
az network public-ip update --ids $publicIpResourceId --dns-name ${resourcesPrefix}
echo "Public IP DNS Label has been updated to ${resourcesPrefix}"

#=============================================#
#======== Create Connected-ARC Cluster =======#
#=============================================#
echo -e "\tConnecting AKS to ARC-AKS -- ***start***"
az connectedk8s connect --name ${connectedClusterName} --resource-group $rg --yes
echo "Performing AKS-Arc-connected connectivity Sanity test"
connectedResult=$(az connectedk8s show --name ${connectedClusterName} --resource-group $rg 2>&1)
if [[ "$connectedResult" == *"ERROR"* ]]; then
echo "AKS-Arc-connected connectivity Sanity test failed. Exiting"
exit 1
fi


echo "==============================="
echo "AKS Cluster has been deployed . you can now move on to install video indexer extension"
echo "==============================="